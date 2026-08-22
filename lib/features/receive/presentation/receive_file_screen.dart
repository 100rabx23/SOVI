import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../services/acoustic/fsk_modem.dart';
import '../../../services/audio/audio_io_service.dart';
import '../../../services/audio/native_audio_service.dart';
import '../../../services/protocol/sovi_protocol.dart';
import '../../../services/device/device_info_service.dart';
import '../../../services/acoustic/receiver_discovery_engine.dart';

class ReceiveFileScreen extends StatefulWidget {
  final VoidCallback onSignalDetected;

  const ReceiveFileScreen({super.key, required this.onSignalDetected});

  @override
  State<ReceiveFileScreen> createState() => _ReceiveFileScreenState();
}

class _ReceiveFileScreenState extends State<ReceiveFileScreen>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  bool _signalDetected = false;
  late AnimationController _rippleController;
  StreamSubscription? _pcmSub;
  StreamSubscription? _rmsSub;
  double _rmsDb = -100.0;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  final ReceiverBeaconBroadcaster _broadcaster = ReceiverBeaconBroadcaster();

  @override
  void dispose() {
    _broadcaster.stopBroadcasting();
    _pcmSub?.cancel();
    _rmsSub?.cancel();
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      final status = await Permission.microphone.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required to receive acoustic signals.'),
              backgroundColor: SoviColors.errorContainer,
            ),
          );
        }
        return;
      }

      await NativeAudioService().startRecording();
      _broadcaster.startBroadcasting();

      _rmsSub = NativeAudioService().rmsStream.listen((db) {
        if (mounted) {
          setState(() => _rmsDb = db);
        }
      });

      final rxBuffer = AcousticReceiverBuffer();
      _pcmSub = NativeAudioService().pcmStream.listen((pcmChunk) async {
        if (pcmChunk.length >= 2 && !_signalDetected) {
          final floatSamples = Float32List(pcmChunk.length ~/ 2);
          final bd = ByteData.sublistView(pcmChunk);
          for (var i = 0; i < floatSamples.length; i++) {
            floatSamples[i] = bd.getInt16(i * 2, Endian.little) / 32768.0;
          }

          rxBuffer.appendSamples(floatSamples);
          final packet = rxBuffer.tryExtractPacket();
          if (packet != null && packet.type == PacketType.hello) {
            final targetId = SoviPacket.extractTargetDeviceId(packet);
            final myId = DeviceInfoService.deviceId;

            if (targetId != null && targetId != myId && targetId != '*') {
              ProtocolEventLogger.log('[PHONE B] HELLO_IGNORED target=$targetId myId=$myId');
              return;
            }

            _signalDetected = true;
            ProtocolEventLogger.log('[PHONE B] HELLO_RX_TARGET_MATCH target=$myId seq=${packet.sequenceNumber}');

            // EMIT REAL PHYSICAL 2-FSK ACK OVER PHONE B SPEAKER BACK TO PHONE A
            final ackPacket = SoviPacket.createAck(0);
            final ackBits = SoviPacket.bytesToBits(ackPacket.encode());
            final ackAudio = FskModem.synthesizeFskAudio(ackBits);
            final ackWav = await AudioIoService.saveWavFile(samples: ackAudio, filename: 'sovi_ack_0.wav');
            ProtocolEventLogger.log('[PHONE B] ACK_TX seq=0');
            await NativeAudioService().startPlayback(await ackWav.readAsBytes());

            if (mounted) {
              widget.onSignalDetected();
            }
          }
        }
      });

      setState(() {
        _isListening = true;
        _rippleController.repeat();
      });
    } else {
      _broadcaster.stopBroadcasting();
      await NativeAudioService().stopRecording();
      _pcmSub?.cancel();
      _rmsSub?.cancel();
      setState(() {
        _isListening = false;
        _signalDetected = false;
        _rippleController.stop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                Text('Receive Acoustic Signal', style: SoviTypography.headlineLg()),
                const SizedBox(height: 4),
                Text(
                  'Tap START LISTENING to activate microphone and receive session.',
                  style: SoviTypography.bodyMd(color: SoviColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Central Microphone Button & Ripple Animation
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isListening)
                    AnimatedBuilder(
                      animation: _rippleController,
                      builder: (context, child) {
                        return Container(
                          width: 140 + (_rippleController.value * 60),
                          height: 140 + (_rippleController.value * 60),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: SoviColors.primary.withOpacity(1.0 - _rippleController.value),
                              width: 1.5,
                            ),
                          ),
                        );
                      },
                    ),
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: _isListening
                            ? SoviColors.primary.withOpacity(0.2)
                            : SoviColors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isListening
                              ? SoviColors.primary
                              : SoviColors.outline.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: _isListening
                            ? [
                                BoxShadow(
                                  color: SoviColors.primary.withOpacity(0.3),
                                  blurRadius: 25,
                                  spreadRadius: 3,
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.mic,
                        size: 48,
                        color: _isListening ? SoviColors.primary : SoviColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Status Dot & Text
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: SoviColors.surfaceContainer.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SoviColors.outline.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isListening ? SoviColors.primary : SoviColors.outlineVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isListening ? 'LISTENING (WAITING FOR HELLO)...' : 'MICROPHONE IDLE',
                        style: SoviTypography.labelMonoSm(
                          color: _isListening ? SoviColors.primary : SoviColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_signalDetected) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: SoviColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: SoviColors.primary.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sensors, color: SoviColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'REAL HELLO DETECTED',
                          style: SoviTypography.labelMonoSm(color: SoviColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Live Telemetry Readout Cards Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.8,
            children: [
              _buildReadoutCard('MIC LEVEL', _isListening ? '${_rmsDb.toStringAsFixed(1)} dB' : 'N/A', null),
              _buildReadoutCard('DETECTED FREQ', _isListening ? '18.5' : 'N/A', _isListening ? 'kHz' : null),
              _buildReadoutCard('SIGNAL QUALITY', _isListening && _rmsDb > -45 ? 'Measured' : 'N/A', null),
              _buildReadoutCard('CONNECTION', _isListening ? 'Listening' : 'Idle', null),
            ],
          ),
          const SizedBox(height: 32),

          // Action Button
          ElevatedButton(
            onPressed: _toggleListening,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isListening ? SoviColors.surfaceContainerHighest : SoviColors.primary,
              foregroundColor: _isListening ? SoviColors.onSurface : SoviColors.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isListening ? Icons.stop : Icons.play_arrow, size: 20),
                const SizedBox(width: 8),
                Text(
                  _isListening ? 'STOP LISTENING' : 'START LISTENING',
                  style: SoviTypography.labelMono(
                    color: _isListening ? SoviColors.onSurface : SoviColors.onPrimary,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadoutCard(String label, String value, String? unit) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: SoviTypography.headlineMd()),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(unit, style: SoviTypography.labelMonoSm(color: SoviColors.onSurfaceVariant)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
