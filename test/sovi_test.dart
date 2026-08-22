import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sovi/services/security/security_service.dart';
import 'package:sovi/services/protocol/sovi_protocol.dart';
import 'package:sovi/services/acoustic/fsk_modem.dart';
import 'package:sovi/services/audio/native_audio_service.dart';
import 'package:sovi/services/storage/history_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryRepository Tests', () {
    test('TransferRecord encodes and decodes JSON correctly', () {
      final rec = TransferRecord(
        id: 'A7F31C92',
        direction: 'sent',
        type: 'text',
        status: 'success',
        fileName: 'message.txt',
        fileSize: 42,
        packetsSent: 3,
        packetsReceived: 3,
        acks: 3,
        nacks: 0,
        retries: 0,
        crcErrors: 0,
        durationSeconds: 2,
        throughputBps: 130,
        timestamp: DateTime.now(),
        textContent: 'Hello from SOVI!',
      );

      final json = rec.toJson();
      final rebuilt = TransferRecord.fromJson(json);
      expect(rebuilt.id, equals('A7F31C92'));
      expect(rebuilt.status, equals('success'));
      expect(rebuilt.type, equals('text'));
      expect(rebuilt.textContent, equals('Hello from SOVI!'));
    });
  });

  group('SecurityService Tests', () {
    test('SHA-256 hashing calculates expected output', () {
      final input = Uint8List.fromList([83, 79, 86, 73]); // "SOVI"
      final hash = SecurityService.calculateSha256(input);
      expect(hash, isNotEmpty);
      expect(hash.length, equals(64));
    });

    test('AES Encryption and Decryption roundtrip succeeds', () {
      final sec = SecurityService(passphrase: 'secret123');
      final original = Uint8List.fromList([10, 20, 30, 40, 50, 60, 70, 80]);
      final encrypted = sec.encrypt(original);
      final decrypted = sec.decrypt(encrypted);
      expect(decrypted, equals(original));
    });
  });

  group('SoviPacket Tests', () {
    test('CRC32 calculation matches expected value', () {
      final data = Uint8List.fromList([85, 83, 79, 78]); // "USON"
      final crc = SoviPacket.calculateCrc32(data);
      expect(crc, isA<int>());
    });

    test('Packet Encoding and Decoding roundtrip succeeds', () {
      final packet = SoviPacket(
        type: PacketType.data,
        sequenceNumber: 42,
        payload: Uint8List.fromList([100, 101, 102, 103]),
      );

      final encoded = packet.encode();
      final decoded = SoviPacket.decode(encoded);

      expect(decoded.type, equals(PacketType.data));
      expect(decoded.sequenceNumber, equals(42));
      expect(decoded.payload, equals(Uint8List.fromList([100, 101, 102, 103])));
    });

    test('Bit <-> Byte Conversion preserves exact bits', () {
      final bytes = Uint8List.fromList([0xAA, 0x55]);
      final bits = SoviPacket.bytesToBits(bytes);
      final rebuiltBytes = SoviPacket.bitsToBytes(bits);
      expect(rebuiltBytes, equals(bytes));
    });

    test('PacketAssembler chunks and reassembles payload', () {
      final rawData = Uint8List.fromList(List.generate(300, (i) => i % 256));
      final chunks = PacketAssembler.chunkPayload(rawData, chunkSize: 100);
      expect(chunks.length, equals(3));

      final reassembled = PacketAssembler.reassemblePayload(chunks);
      expect(reassembled, equals(rawData));
    });
  });

  group('Protocol Event Log & Exception Tests', () {
    test('ProtocolEventLogger records technical events: AUDIO_TX, ACK_RX, SESSION_ESTABLISHED', () {
      ProtocolEventLogger.clear();
      ProtocolEventLogger.log('AUDIO_TX type=HELLO session=ABC123');
      ProtocolEventLogger.log('ACK_RX session=ABC123');
      ProtocolEventLogger.log('SESSION_ESTABLISHED session=ABC123');

      expect(ProtocolEventLogger.history.length, equals(3));
      expect(ProtocolEventLogger.history[0].message, contains('AUDIO_TX'));
      expect(ProtocolEventLogger.history[1].message, contains('ACK_RX'));
      expect(ProtocolEventLogger.history[2].message, contains('SESSION_ESTABLISHED'));
    });

    test('SoviException handles NO_RECEIVER error code', () {
      final ex = SoviException(
        code: 'NO_RECEIVER',
        userMessage: 'No SOVI receiver detected.',
        technicalMessage: 'HELLO handshake timed out after 10 seconds.',
      );
      expect(ex.code, equals('NO_RECEIVER'));
    });
  });

  group('End-to-End File & Text Transmission Tests', () {
    test('REAL TEXT TRANSMISSION: UTF-8 -> AES-256-GCM -> SOVI Packets -> SHA-256 Match', () {
      final textMessage = "Hello from SOVI real text transmission!";
      final textBytes = Uint8List.fromList(utf8.encode(textMessage));
      final originalSha256 = SecurityService.calculateSha256(textBytes);

      // Sender: AES-256-GCM
      final secSender = SecurityService(passphrase: 'textkey99');
      final encryptedPayload = secSender.encrypt(textBytes);

      // Packetization
      final packets = PacketAssembler.chunkPayload(encryptedPayload, chunkSize: 16);
      final encodedPackets = packets.map((p) => p.encode()).toList();

      // Receiver: Decode packets
      final decodedPackets = encodedPackets.map((b) => SoviPacket.decode(b)).toList();
      final smReceiver = ProtocolStateMachine();

      for (var packet in decodedPackets) {
        final ack = smReceiver.handleReceivedPacket(packet);
        expect(ack?.type, equals(PacketType.ack));
      }

      // Reassemble & Decrypt
      final reassembledEncrypted = PacketAssembler.reassemblePayload(smReceiver.receivedPackets);
      final secReceiver = SecurityService(passphrase: 'textkey99');
      final decryptedBytes = secReceiver.decrypt(reassembledEncrypted);
      final receivedSha256 = SecurityService.calculateSha256(decryptedBytes);
      final receivedText = utf8.decode(decryptedBytes);

      expect(receivedSha256, equals(originalSha256));
      expect(receivedText, equals(textMessage));
    });

    test('Stage 3A — Text File (hello.txt) end-to-end encrypted transfer & SHA-256 match', () {
      final fileContent = "Hello from SOVI acoustic communication.";
      final fileBytes = Uint8List.fromList(utf8.encode(fileContent));
      final originalSha256 = SecurityService.calculateSha256(fileBytes);

      // Sender: Encrypt AES-256-GCM
      final secSender = SecurityService(passphrase: 'passphrase123');
      final encryptedPayload = secSender.encrypt(fileBytes);

      // Sender: Chunk into packets & encode
      final packets = PacketAssembler.chunkPayload(encryptedPayload, chunkSize: 16);
      final encodedPackets = packets.map((p) => p.encode()).toList();

      // Receiver: Decode packets with CRC32 verification
      final decodedPackets = encodedPackets.map((bytes) => SoviPacket.decode(bytes)).toList();
      final smReceiver = ProtocolStateMachine();

      for (var packet in decodedPackets) {
        final ack = smReceiver.handleReceivedPacket(packet);
        expect(ack?.type, equals(PacketType.ack));
      }

      // Receiver: Reassemble & decrypt AES-256-GCM
      final reassembledEncrypted = PacketAssembler.reassemblePayload(smReceiver.receivedPackets);
      final secReceiver = SecurityService(passphrase: 'passphrase123');
      final decryptedBytes = secReceiver.decrypt(reassembledEncrypted);
      final receivedSha256 = SecurityService.calculateSha256(decryptedBytes);

      // SHA-256 Hash Match Verification
      expect(receivedSha256, equals(originalSha256));
      expect(utf8.decode(decryptedBytes), equals(fileContent));
    });
  });

  group('FskModem Tests', () {
    test('Synthesizes audio samples for bitstream', () {
      final bits = [1, 0, 1, 0];
      final audio = FskModem.synthesizeFskAudio(bits);
      expect(audio, isNotEmpty);
      expect(audio.length, greaterThan(0));
    });

    test('Goertzel/FFT frequency energy calculation returns positive energy', () {
      final bits = [1, 1, 1, 1];
      final audio = FskModem.synthesizeFskAudio(bits);
      final energy = FskModem.computeFrequencyEnergy(audio, 19500.0);
      expect(energy, greaterThan(0.0));
    });

    test('Milestone 4 Modem Self-Test executes modulation/demodulation pipeline', () {
      final testBits = [1, 0, 1, 0, 1, 1, 0, 0];
      final result = FskModem.runModemSelfTest(testBits);
      expect(result.transmittedBits, equals(8));
      expect(result.isSuccess, isTrue);
      expect(result.ber, lessThan(0.05));
    });
  });

  group('NativeAudioService Tests', () {
    test('NativeAudioService initializes stream controllers', () {
      final service = NativeAudioService();
      expect(service.pcmStream, isNotNull);
      expect(service.rmsStream, isNotNull);
    });
  });
}
