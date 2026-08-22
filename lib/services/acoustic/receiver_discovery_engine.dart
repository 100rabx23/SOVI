import 'dart:async';
import 'dart:typed_data';
import '../protocol/sovi_protocol.dart';
import '../acoustic/fsk_modem.dart';
import '../audio/audio_io_service.dart';
import '../audio/native_audio_service.dart';
import '../device/device_info_service.dart';

class DiscoveredReceiver {
  final String deviceId;
  final String displayName;
  final String status;
  final DateTime lastSeen;
  final double? measuredRmsDb;

  DiscoveredReceiver({
    required this.deviceId,
    required this.displayName,
    required this.status,
    required this.lastSeen,
    this.measuredRmsDb,
  });

  bool get isExpired => DateTime.now().difference(lastSeen).inSeconds > 8;

  String get signalQuality {
    if (measuredRmsDb == null) return 'Good';
    if (measuredRmsDb! > -35.0) return 'Strong';
    if (measuredRmsDb! > -55.0) return 'Good';
    return 'Weak';
  }
}

class ReceiverDiscoveryScanner {
  final Map<String, DiscoveredReceiver> _receivers = {};
  final StreamController<List<DiscoveredReceiver>> _controller = StreamController.broadcast();
  StreamSubscription? _pcmSub;
  StreamSubscription? _rmsSub;
  Timer? _purgeTimer;
  double _lastRmsDb = -50.0;
  final AcousticReceiverBuffer _rxBuffer = AcousticReceiverBuffer();

  Stream<List<DiscoveredReceiver>> get stream => _controller.stream;
  List<DiscoveredReceiver> get activeReceivers =>
      _receivers.values.where((r) => !r.isExpired).toList();

  Future<void> startScanning() async {
    await stopScanning();
    _receivers.clear();

    await NativeAudioService().startRecording();

    _rmsSub = NativeAudioService().rmsStream.listen((db) {
      _lastRmsDb = db;
    });

    _pcmSub = NativeAudioService().pcmStream.listen((pcmChunk) {
      if (pcmChunk.length < 2) return;

      final floatSamples = Float32List(pcmChunk.length ~/ 2);
      final bd = ByteData.sublistView(pcmChunk);
      for (var i = 0; i < floatSamples.length; i++) {
        floatSamples[i] = bd.getInt16(i * 2, Endian.little) / 32768.0;
      }

      _rxBuffer.appendSamples(floatSamples);

      while (true) {
        final packet = _rxBuffer.tryExtractPacket();
        if (packet == null) break;

        if (packet.type == PacketType.discoveryBeacon) {
          final beacon = SoviDiscoveryBeacon.decode(packet.payload, rmsDb: _lastRmsDb);
          _receivers[beacon.deviceId] = DiscoveredReceiver(
            deviceId: beacon.deviceId,
            displayName: beacon.displayName,
            status: beacon.status,
            lastSeen: DateTime.now(),
            measuredRmsDb: _lastRmsDb,
          );
          _controller.add(activeReceivers);
        }
      }
    });

    _purgeTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _receivers.removeWhere((id, r) => r.isExpired);
      _controller.add(activeReceivers);
    });
  }

  Future<void> stopScanning() async {
    _purgeTimer?.cancel();
    _pcmSub?.cancel();
    _rmsSub?.cancel();
    _purgeTimer = null;
    _pcmSub = null;
    _rmsSub = null;
    await NativeAudioService().stopRecording();
  }

  void addSimulatedReceiver(DiscoveredReceiver r) {
    _receivers[r.deviceId] = r;
    _controller.add(activeReceivers);
  }
}

class ReceiverBeaconBroadcaster {
  Timer? _beaconTimer;
  bool _isBroadcasting = false;

  bool get isBroadcasting => _isBroadcasting;

  void startBroadcasting() {
    stopBroadcasting();
    _isBroadcasting = true;

    _beaconTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) async {
      if (!_isBroadcasting) return;

      final beacon = SoviDiscoveryBeacon(
        deviceId: DeviceInfoService.deviceId,
        displayName: DeviceInfoService.displayName,
        status: 'READY',
      );

      final packet = SoviPacket.createBeacon(beacon);
      final bits = SoviPacket.bytesToBits(packet.encode());
      final audio = FskModem.synthesizeFskAudio(bits);
      final wav = await AudioIoService.saveWavFile(samples: audio, filename: 'sovi_beacon.wav');

      await NativeAudioService().startPlayback(await wav.readAsBytes());
    });
  }

  void stopBroadcasting() {
    _isBroadcasting = false;
    _beaconTimer?.cancel();
    _beaconTimer = null;
  }
}
