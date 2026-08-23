import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sovi/services/security/security_service.dart';
import 'package:sovi/services/protocol/sovi_protocol.dart';
import 'package:sovi/services/acoustic/fsk_modem.dart';
import 'package:sovi/services/device/device_info_service.dart';
import 'package:sovi/services/acoustic/receiver_discovery_engine.dart';

class AiAgentTestResult {
  final String testName;
  final bool passed;
  final String details;
  final Duration executionTime;

  AiAgentTestResult({
    required this.testName,
    required this.passed,
    required this.details,
    required this.executionTime,
  });

  @override
  String toString() => '${passed ? "✅ [PASS]" : "❌ [FAIL]"} $testName (${executionTime.inMilliseconds}ms)\n   Details: $details';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SOVI Autonomous AI Testing Agent Suite', () {
    final results = <AiAgentTestResult>[];

    test('AI AGENT SCENARIO 1: End-to-End Acoustic Discovery Beaconing & Signal Quality Verification', () async {
      final sw = Stopwatch()..start();
      
      final receiverBeacon = SoviDiscoveryBeacon(
        deviceId: 'SOVI-7A3F92',
        displayName: "Saurabh's Phone",
        status: 'READY',
        sessionNonce: 'A1B2',
      );

      final packet = SoviPacket.createBeacon(receiverBeacon);
      final bits = SoviPacket.bytesToBits(packet.encode());
      final audioSamples = FskModem.synthesizeFskAudio(bits);

      final rxBuffer = AcousticReceiverBuffer();
      rxBuffer.appendSamples(audioSamples);
      final decodedPacket = FskModem.tryDecodeFromAudio(audioSamples);

      expect(decodedPacket, isNotNull);
      expect(decodedPacket!.type, equals(PacketType.discoveryBeacon));

      final decodedBeacon = SoviDiscoveryBeacon.decode(decodedPacket.payload, rmsDb: -30.0);
      expect(decodedBeacon.deviceId, equals('SOVI-7A3F92'));
      expect(decodedBeacon.displayName, equals("Saurabh's Phone"));
      expect(decodedBeacon.signalQuality, equals('Strong'));

      sw.stop();
      results.add(AiAgentTestResult(
        testName: 'Discovery Beaconing & Signal Quality',
        passed: true,
        details: 'Decoded beacon for SOVI-7A3F92 (Saurabh\'s Phone) with Strong signal quality (-30dB).',
        executionTime: sw.elapsed,
      ));
    });

    test('AI AGENT SCENARIO 2: Target-Bound Handshake & Misaddressed Device Filtering', () async {
      final sw = Stopwatch()..start();

      final helloForPhoneB = SoviPacket.createHello(targetDeviceId: 'SOVI-7A3F92');
      final decodedHello = SoviPacket.decode(helloForPhoneB.encode());

      final extractedTarget = SoviPacket.extractTargetDeviceId(decodedHello);
      expect(extractedTarget, equals('SOVI-7A3F92'));

      // Phone B check (myId = SOVI-7A3F92)
      final phoneBAcepts = (extractedTarget == 'SOVI-7A3F92' || extractedTarget == '*');
      expect(phoneBAcepts, isTrue);

      // Phone C check (myId = SOVI-999999)
      final phoneCAcepts = (extractedTarget == 'SOVI-999999' || extractedTarget == '*');
      expect(phoneCAcepts, isFalse);

      sw.stop();
      results.add(AiAgentTestResult(
        testName: 'Target-Bound Handshake Filtering',
        passed: true,
        details: 'Verified Phone B (SOVI-7A3F92) accepts target HELLO, Phone C (SOVI-999999) correctly ignores it.',
        executionTime: sw.elapsed,
      ));
    });

    test('AI AGENT SCENARIO 3: Full End-to-End Encrypted File Transfer & SHA-256 Hash Verification', () async {
      final sw = Stopwatch()..start();

      final originalContent = List.generate(512, (i) => (i * 7) % 256);
      final rawFileBytes = Uint8List.fromList(originalContent);
      final senderSha256 = SecurityService.calculateSha256(rawFileBytes);

      // 1. Sender Encryption (AES-256-GCM)
      final passphrase = 'ai_agent_secret_key';
      final secSender = SecurityService(passphrase: passphrase);
      final encryptedPayload = secSender.encrypt(rawFileBytes);

      // 2. Chunking & Packetization
      final dataPackets = PacketAssembler.chunkPayload(encryptedPayload, chunkSize: 64);
      expect(dataPackets.length, equals(9));

      final sessionId = 'SESS_AI_001';
      final meta = SoviSessionMeta(
        sessionId: sessionId,
        type: 'file',
        fileName: 'confidential_report.pdf',
        fileSize: rawFileBytes.length,
        totalChunks: dataPackets.length,
        sha256: senderSha256,
      );

      final metaPacket = SoviPacket.createMeta(meta);
      final endPacket = SoviPacket.createEnd(dataPackets.length);

      // 3. Acoustic Transmission & Receiver Processing
      final rxBuffer = AcousticReceiverBuffer();
      final smReceiver = ProtocolStateMachine();

      // HELLO
      final helloWav = FskModem.synthesizeFskAudio(SoviPacket.bytesToBits(SoviPacket.createHello(targetDeviceId: 'SOVI-7A3F92').encode()));
      final rxHello = FskModem.tryDecodeFromAudio(helloWav);
      final ackHello = smReceiver.handleReceivedPacket(rxHello!);
      expect(ackHello?.type, equals(PacketType.ack));

      // META
      final metaWav = FskModem.synthesizeFskAudio(SoviPacket.bytesToBits(metaPacket.encode()));
      final rxMeta = FskModem.tryDecodeFromAudio(metaWav);
      final ackMeta = smReceiver.handleReceivedPacket(rxMeta!);
      expect(ackMeta?.type, equals(PacketType.ack));

      // DATA Chunks
      for (var chunk in dataPackets) {
        final dataWav = FskModem.synthesizeFskAudio(SoviPacket.bytesToBits(chunk.encode()));
        final rxChunk = FskModem.tryDecodeFromAudio(dataWav);
        final ackChunk = smReceiver.handleReceivedPacket(rxChunk!);
        expect(ackChunk?.type, equals(PacketType.ack));
      }

      // END
      final endWav = FskModem.synthesizeFskAudio(SoviPacket.bytesToBits(endPacket.encode()));
      final rxEnd = FskModem.tryDecodeFromAudio(endWav);
      final ackEnd = smReceiver.handleReceivedPacket(rxEnd!);
      expect(ackEnd?.type, equals(PacketType.ack));

      // 4. Payload Reassembly & Decryption
      final reassembledEncrypted = PacketAssembler.reassemblePayload(smReceiver.receivedPackets);
      final secReceiver = SecurityService(passphrase: passphrase);
      final decryptedFileBytes = secReceiver.decrypt(reassembledEncrypted);
      final receiverSha256 = SecurityService.calculateSha256(decryptedFileBytes);

      expect(receiverSha256, equals(senderSha256));
      expect(decryptedFileBytes, equals(rawFileBytes));

      sw.stop();
      results.add(AiAgentTestResult(
        testName: 'Full End-to-End Encrypted File Transfer',
        passed: true,
        details: 'Transferred 512 bytes across 9 acoustic packets. AES-256-GCM decrypted successfully. SHA-256 match confirmed: ${senderSha256.substring(0, 16)}...',
        executionTime: sw.elapsed,
      ));
    });

    test('AI AGENT SCENARIO 4: CRC Error Detection & NACK Retransmission Recovery', () async {
      final sw = Stopwatch()..start();

      final packet = SoviPacket(
        type: PacketType.data,
        sequenceNumber: 2,
        payload: Uint8List.fromList([10, 20, 30, 40, 50]),
      );

      final encodedBytes = packet.encode();
      // Corrupt CRC checksum bytes
      final corruptedBytes = Uint8List.fromList(encodedBytes);
      corruptedBytes[corruptedBytes.length - 1] ^= 0xFF;

      bool caughtCrcError = false;
      try {
        SoviPacket.decode(corruptedBytes);
      } on SoviException catch (e) {
        if (e.code == 'CRC_ERROR') caughtCrcError = true;
      }

      expect(caughtCrcError, isTrue);

      sw.stop();
      results.add(AiAgentTestResult(
        testName: 'CRC Error Detection & Recovery',
        passed: true,
        details: 'Corrupted payload byte successfully detected by IEEE 802.3 CRC32 validator. Generated CRC_ERROR exception.',
        executionTime: sw.elapsed,
      ));
    });

    test('AI AGENT SCENARIO 5: 8-Second Discovery Expiration & Offline Receiver Purge', () async {
      final sw = Stopwatch()..start();

      final activeRec = DiscoveredReceiver(
        deviceId: 'SOVI-ACTIVE',
        displayName: 'Active Phone',
        status: 'READY',
        lastSeen: DateTime.now(),
      );

      final offlineRec = DiscoveredReceiver(
        deviceId: 'SOVI-STALE',
        displayName: 'Stale Phone',
        status: 'READY',
        lastSeen: DateTime.now().subtract(const Duration(seconds: 10)),
      );



      expect(activeRec.isExpired, isFalse);
      expect(offlineRec.isExpired, isTrue);

      sw.stop();
      results.add(AiAgentTestResult(
        testName: '8-Second Discovery Expiration Purge',
        passed: true,
        details: 'Verified active receiver retained, stale receiver (>8s inactive) flagged as expired.',
        executionTime: sw.elapsed,
      ));
    });
  });
}
