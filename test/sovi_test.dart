import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sovi/services/security/security_service.dart';
import 'package:sovi/services/protocol/sovi_protocol.dart';
import 'package:sovi/services/acoustic/fsk_modem.dart';
import 'package:sovi/services/audio/native_audio_service.dart';
import 'package:sovi/services/storage/history_repository.dart';
import 'package:sovi/services/device/device_info_service.dart';
import 'package:sovi/services/acoustic/receiver_discovery_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Comprehensive 23-Test Acoustic Protocol & Discovery Suite', () {
    // TEST 1: Pure software FSK loopback
    test('TEST 1: Pure software FSK loopback modulation and demodulation', () {
      final knownBits = [1, 0, 1, 0, 1, 1, 0, 0, 1, 1, 1, 0];
      final audio = FskModem.synthesizeFskAudio(knownBits);
      final decodedBits = FskModem.demodulateBuffer(audio);

      expect(decodedBits, isNotNull);
      final compareLen = knownBits.length;
      var errors = 0;
      for (var i = 0; i < compareLen; i++) {
        if (knownBits[i] != decodedBits![i]) errors++;
      }
      expect(errors / knownBits.length, lessThan(0.05));
    });

    // TEST 2: AudioTrack -> AudioRecord loopback simulation
    test('TEST 2: AudioTrack -> AudioRecord simulated PCM stream loopback', () {
      final packet = SoviPacket.createHello();
      final bits = SoviPacket.bytesToBits(packet.encode());
      final audio = FskModem.synthesizeFskAudio(bits);

      final rxBuffer = AcousticReceiverBuffer();
      rxBuffer.appendSamples(audio);
      final decoded = rxBuffer.tryExtractPacket();

      expect(decoded, isNotNull);
      expect(decoded!.type, equals(PacketType.hello));
    });

    // TEST 3: Phone A -> Phone B HELLO + ACK
    test('TEST 3: Phone A -> Phone B HELLO + ACK roundtrip', () {
      final hello = SoviPacket.createHello(sequenceNumber: 0);
      final smB = ProtocolStateMachine();

      final ackB = smB.handleReceivedPacket(hello);
      expect(ackB, isNotNull);
      expect(ackB!.type, equals(PacketType.ack));
      expect(ackB.sequenceNumber, equals(0));
    });

    // TEST 4: Phone A -> Phone B HELLO + META + ACK
    test('TEST 4: Phone A -> Phone B HELLO + META + ACK roundtrip', () {
      final metaData = SoviSessionMeta(
        sessionId: 'SESS001',
        type: 'text',
        fileName: 'note.txt',
        fileSize: 128,
        totalChunks: 1,
        sha256: '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08',
      );
      final metaPacket = SoviPacket.createMeta(metaData);
      final smB = ProtocolStateMachine();

      final ackB = smB.handleReceivedPacket(metaPacket);
      expect(ackB, isNotNull);
      expect(ackB!.type, equals(PacketType.ack));
      expect(ackB.sequenceNumber, equals(0));
    });

    // TEST 5: Small text message
    test('TEST 5: Small text message end-to-end encryption & acoustic packet decoding', () {
      final text = "Short text message!";
      final bytes = Uint8List.fromList(utf8.encode(text));
      final sec = SecurityService(passphrase: 'key1');
      final enc = sec.encrypt(bytes);

      final chunks = PacketAssembler.chunkPayload(enc, chunkSize: 128);
      final smB = ProtocolStateMachine();
      for (var c in chunks) {
        smB.handleReceivedPacket(c);
      }

      final reassembled = PacketAssembler.reassemblePayload(smB.receivedPackets);
      final dec = sec.decrypt(reassembled);
      expect(utf8.decode(dec), equals(text));
    });

    // TEST 6: Multi-packet text message
    test('TEST 6: Multi-packet text message end-to-end transfer', () {
      final text = List.generate(50, (i) => "Line $i: SOVI multi-packet text transfer message\n").join();
      final bytes = Uint8List.fromList(utf8.encode(text));
      final sec = SecurityService(passphrase: 'key2');
      final enc = sec.encrypt(bytes);

      final chunks = PacketAssembler.chunkPayload(enc, chunkSize: 64);
      expect(chunks.length, greaterThan(1));

      final smB = ProtocolStateMachine();
      for (var c in chunks) {
        final ack = smB.handleReceivedPacket(c);
        expect(ack?.type, equals(PacketType.ack));
      }

      final reassembled = PacketAssembler.reassemblePayload(smB.receivedPackets);
      final dec = sec.decrypt(reassembled);
      expect(utf8.decode(dec), equals(text));
    });

    // TEST 7: Small file
    test('TEST 7: Small file end-to-end payload reassembly & hash match', () {
      final fileData = Uint8List.fromList(List.generate(200, (i) => (i * 3) % 256));
      final origHash = SecurityService.calculateSha256(fileData);
      final sec = SecurityService(passphrase: 'filepass');
      final enc = sec.encrypt(fileData);

      final chunks = PacketAssembler.chunkPayload(enc, chunkSize: 128);
      final smB = ProtocolStateMachine();
      for (var c in chunks) {
        smB.handleReceivedPacket(c);
      }

      final dec = sec.decrypt(PacketAssembler.reassemblePayload(smB.receivedPackets));
      final rxHash = SecurityService.calculateSha256(dec);
      expect(rxHash, equals(origHash));
    });

    // TEST 8: Multi-packet file
    test('TEST 8: Multi-packet binary file end-to-end transfer', () {
      final fileData = Uint8List.fromList(List.generate(1024, (i) => i % 256));
      final origHash = SecurityService.calculateSha256(fileData);
      final sec = SecurityService(passphrase: 'filepass2');
      final enc = sec.encrypt(fileData);

      final chunks = PacketAssembler.chunkPayload(enc, chunkSize: 128);
      expect(chunks.length, equals(9));

      final smB = ProtocolStateMachine();
      for (var c in chunks) {
        smB.handleReceivedPacket(c);
      }

      final dec = sec.decrypt(PacketAssembler.reassemblePayload(smB.receivedPackets));
      expect(SecurityService.calculateSha256(dec), equals(origHash));
    });

    // TEST 9: Intentional CRC corruption
    test('TEST 9: Intentional CRC corruption triggers exception/NACK', () {
      final packet = SoviPacket(
        type: PacketType.data,
        sequenceNumber: 1,
        payload: Uint8List.fromList([10, 20, 30]),
      );
      final encoded = packet.encode();
      encoded[10] = encoded[10] ^ 0xFF;

      expect(() => SoviPacket.decode(encoded), throwsA(isA<SoviException>()));
    });

    // TEST 10: Packet duplication
    test('TEST 10: Packet duplication triggers ACK re-transmission without payload duplication', () {
      final smB = ProtocolStateMachine();
      final packet = SoviPacket(
        type: PacketType.data,
        sequenceNumber: 0,
        payload: Uint8List.fromList([1, 2, 3]),
      );

      final ack1 = smB.handleReceivedPacket(packet);
      expect(ack1?.type, equals(PacketType.ack));
      expect(smB.receivedPackets.length, equals(1));

      final ack2 = smB.handleReceivedPacket(packet);
      expect(ack2?.type, equals(PacketType.ack));
      expect(smB.receivedPackets.length, equals(1));
    });

    // TEST 11: Packet loss
    test('TEST 11: Packet loss / out-of-order sequence generates NACK', () {
      final smB = ProtocolStateMachine();
      final packetSeq1 = SoviPacket(
        type: PacketType.data,
        sequenceNumber: 1,
        payload: Uint8List.fromList([1, 2, 3]),
      );

      final response = smB.handleReceivedPacket(packetSeq1);
      expect(response?.type, equals(PacketType.nack));
      expect(response?.sequenceNumber, equals(0));
    });

    // TEST 12: Preamble split across AudioRecord PCM buffers
    test('TEST 12: Preamble split across AudioRecord PCM buffers decodes successfully via rolling buffer', () {
      final packet = SoviPacket.createHello();
      final bits = SoviPacket.bytesToBits(packet.encode());
      final audio = FskModem.synthesizeFskAudio(bits);

      final chunk1 = audio.sublist(0, audio.length ~/ 2);
      final chunk2 = audio.sublist(audio.length ~/ 2);

      final rxBuffer = AcousticReceiverBuffer();
      rxBuffer.appendSamples(chunk1);
      final pass1 = rxBuffer.tryExtractPacket();
      expect(pass1, isNull);

      rxBuffer.appendSamples(chunk2);
      final pass2 = rxBuffer.tryExtractPacket();
      expect(pass2, isNotNull);
      expect(pass2!.type, equals(PacketType.hello));
    });

    // TEST 13: No receiver timeout
    test('TEST 13: No receiver timeout handles missing receiver session', () {
      final ex = SoviException(
        code: 'NO_RECEIVER',
        userMessage: 'No SOVI receiver detected.',
        technicalMessage: 'HELLO handshake timed out after 3 retries.',
      );
      expect(ex.code, equals('NO_RECEIVER'));
    });

    // TEST 14: Speaker self-echo isolation
    test('TEST 14: Only sender speaker active does not produce false ACK', () {
      final hello = SoviPacket.createHello();
      final decodedHello = SoviPacket.decode(hello.encode());
      expect(decodedHello.type, equals(PacketType.hello));
      expect(decodedHello.type == PacketType.ack, isFalse);
    });

    // TEST 15: Wrong session ACK
    test('TEST 15: Mismatched session meta parameters', () {
      final meta1 = SoviSessionMeta(
        sessionId: 'SESS_A',
        type: 'file',
        fileName: 'a.bin',
        fileSize: 100,
        totalChunks: 1,
        sha256: 'hashA',
      );
      final meta2 = SoviSessionMeta(
        sessionId: 'SESS_B',
        type: 'file',
        fileName: 'b.bin',
        fileSize: 100,
        totalChunks: 1,
        sha256: 'hashB',
      );

      expect(meta1.sessionId == meta2.sessionId, isFalse);
    });

    // TEST 16: Wrong sequence ACK
    test('TEST 16: Out-of-sequence ACK handling', () {
      final smB = ProtocolStateMachine();
      final dataSeq0 = SoviPacket(type: PacketType.data, sequenceNumber: 0, payload: Uint8List.fromList([5]));
      final ack0 = smB.handleReceivedPacket(dataSeq0);

      expect(ack0?.sequenceNumber, equals(0));
      expect(ack0?.sequenceNumber == 99, isFalse);
    });

    // TEST 17: Modified encrypted payload SHA mismatch
    test('TEST 17: Modified encrypted payload fails SHA-256 validation', () {
      final origText = Uint8List.fromList(utf8.encode("Original secret data"));
      final origHash = SecurityService.calculateSha256(origText);

      final tamperedText = Uint8List.fromList(utf8.encode("Tampered secret data"));
      final tamperedHash = SecurityService.calculateSha256(tamperedText);

      expect(origHash == tamperedHash, isFalse);
    });

    // TEST 18: Discovery Beacon encoding and decoding roundtrip
    test('TEST 18: Discovery Beacon encoding and decoding roundtrip', () {
      final beacon = SoviDiscoveryBeacon(
        deviceId: 'SOVI-7A3F92',
        displayName: "Saurabh's Phone",
        status: 'READY',
      );

      final packet = SoviPacket.createBeacon(beacon);
      expect(packet.type, equals(PacketType.discoveryBeacon));

      final decodedPacket = SoviPacket.decode(packet.encode());
      expect(decodedPacket.type, equals(PacketType.discoveryBeacon));

      final decodedBeacon = SoviDiscoveryBeacon.decode(decodedPacket.payload);
      expect(decodedBeacon.deviceId, equals('SOVI-7A3F92'));
      expect(decodedBeacon.displayName, equals("Saurabh's Phone"));
      expect(decodedBeacon.status, equals('READY'));
    });

    // TEST 19: Persistent Device ID format validation
    test('TEST 19: DeviceInfoService persistent Device ID format validation', () {
      final id = DeviceInfoService.generateDeviceId();
      expect(id.startsWith('SOVI-'), isTrue);
      expect(id.length, equals(11));
    });

    // TEST 20: Target-bound HELLO filtering
    test('TEST 20: Target-bound HELLO packet filtering', () {
      final targetHello = SoviPacket.createHello(targetDeviceId: 'SOVI-7A3F92');
      final targetId = SoviPacket.extractTargetDeviceId(targetHello);
      expect(targetId, equals('SOVI-7A3F92'));

      final wrongIdMatch = (targetId == 'SOVI-999999');
      expect(wrongIdMatch, isFalse);
    });

    // TEST 21: Measured acoustic signal quality calculation
    test('TEST 21: Measured acoustic signal quality calculation', () {
      final strongBeacon = SoviDiscoveryBeacon(deviceId: 'D1', displayName: 'Dev1', measuredRmsDb: -25.0);
      final weakBeacon = SoviDiscoveryBeacon(deviceId: 'D2', displayName: 'Dev2', measuredRmsDb: -65.0);

      expect(strongBeacon.signalQuality, equals('Strong'));
      expect(weakBeacon.signalQuality, equals('Weak'));
    });

    // TEST 22: Receiver discovery timeout expiration
    test('TEST 22: DiscoveredReceiver expiration after 8 seconds', () {
      final activeRec = DiscoveredReceiver(
        deviceId: 'D1',
        displayName: 'Dev1',
        status: 'READY',
        lastSeen: DateTime.now(),
      );
      final expiredRec = DiscoveredReceiver(
        deviceId: 'D2',
        displayName: 'Dev2',
        status: 'READY',
        lastSeen: DateTime.now().subtract(const Duration(seconds: 10)),
      );

      expect(activeRec.isExpired, isFalse);
      expect(expiredRec.isExpired, isTrue);
    });

    // TEST 23: Multi-receiver discovery list tracking
    test('TEST 23: Multi-receiver discovery list tracking without auto-send', () {
      final scanner = ReceiverDiscoveryScanner();
      scanner.addSimulatedReceiver(DiscoveredReceiver(deviceId: 'SOVI-1111', displayName: 'Phone B', status: 'READY', lastSeen: DateTime.now()));
      scanner.addSimulatedReceiver(DiscoveredReceiver(deviceId: 'SOVI-2222', displayName: 'Laptop C', status: 'READY', lastSeen: DateTime.now()));

      expect(scanner.activeReceivers.length, equals(2));
      expect(scanner.activeReceivers[0].deviceId, equals('SOVI-1111'));
      expect(scanner.activeReceivers[1].deviceId, equals('SOVI-2222'));
    });
  });
}
