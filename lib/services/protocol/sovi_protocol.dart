import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

enum PacketType { hello, meta, data, ack, nack, end, error }

enum TransferStatus {
  idle,
  preparing,
  discoveringReceiver,
  waitingForReceiver,
  receiverConnected,
  handshake,
  transferring,
  verifying,
  completed,
  failed,
  cancelled,
  timeout,
}

class SoviException implements Exception {
  final String code;
  final String userMessage;
  final String technicalMessage;
  final String? recoveryAction;

  SoviException({
    required this.code,
    required this.userMessage,
    required this.technicalMessage,
    this.recoveryAction,
  });

  @override
  String toString() => 'SoviException[$code]: $userMessage ($technicalMessage)';
}

class SoviLogEntry {
  final DateTime timestamp;
  final String message;
  final bool isError;

  SoviLogEntry({
    required this.timestamp,
    required this.message,
    this.isError = false,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class ProtocolEventLogger {
  static final StreamController<SoviLogEntry> _controller = StreamController<SoviLogEntry>.broadcast();
  static final List<SoviLogEntry> _history = [];

  static Stream<SoviLogEntry> get stream => _controller.stream;
  static List<SoviLogEntry> get history => List.unmodifiable(_history);

  static void log(String message, {bool isError = false}) {
    final entry = SoviLogEntry(timestamp: DateTime.now(), message: message, isError: isError);
    _history.add(entry);
    if (_history.length > 100) _history.removeAt(0);
    _controller.add(entry);
  }

  static void clear() {
    _history.clear();
  }
}

class SoviSessionMeta {
  final String sessionId;
  final String type; // 'file' or 'text'
  final String fileName;
  final int fileSize;
  final int totalChunks;
  final String sha256;

  SoviSessionMeta({
    required this.sessionId,
    required this.type,
    required this.fileName,
    required this.fileSize,
    required this.totalChunks,
    required this.sha256,
  });

  Uint8List encode() {
    final map = {
      'sessionId': sessionId,
      'type': type,
      'fileName': fileName,
      'fileSize': fileSize,
      'totalChunks': totalChunks,
      'sha256': sha256,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(map)));
  }

  static SoviSessionMeta decode(Uint8List bytes) {
    final str = utf8.decode(bytes);
    final map = jsonDecode(str) as Map<String, dynamic>;
    return SoviSessionMeta(
      sessionId: map['sessionId'] as String? ?? generateSessionId(),
      type: map['type'] as String? ?? 'file',
      fileName: map['fileName'] as String,
      fileSize: map['fileSize'] as int,
      totalChunks: map['totalChunks'] as int,
      sha256: map['sha256'] as String,
    );
  }

  static String generateSessionId() {
    final rnd = Random();
    const chars = '0123456789ABCDEF';
    return List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}

class SoviPacket {
  static final Uint8List magic = Uint8List.fromList([0x55, 0x53, 0x4F, 0x4E]); // "USON"
  static const int version = 1;

  final PacketType type;
  final int sequenceNumber;
  final Uint8List payload;

  SoviPacket({
    required this.type,
    required this.sequenceNumber,
    required this.payload,
  });

  /// 16-Bit Reference Preamble
  static const List<int> preambleBits = [
    1, 0, 1, 0,
    1, 1, 0, 0,
    1, 0, 0, 1,
    1, 1, 1, 0
  ];

  static SoviPacket createHello({int sequenceNumber = 0}) {
    return SoviPacket(
      type: PacketType.hello,
      sequenceNumber: sequenceNumber,
      payload: Uint8List(0),
    );
  }

  static SoviPacket createMeta(SoviSessionMeta meta) {
    return SoviPacket(
      type: PacketType.meta,
      sequenceNumber: 0,
      payload: meta.encode(),
    );
  }

  static SoviPacket createAck(int sequenceNumber) {
    return SoviPacket(
      type: PacketType.ack,
      sequenceNumber: sequenceNumber,
      payload: Uint8List(0),
    );
  }

  static SoviPacket createNack(int sequenceNumber) {
    return SoviPacket(
      type: PacketType.nack,
      sequenceNumber: sequenceNumber,
      payload: Uint8List(0),
    );
  }

  static SoviPacket createEnd(int totalChunks) {
    return SoviPacket(
      type: PacketType.end,
      sequenceNumber: totalChunks,
      payload: Uint8List(0),
    );
  }

  /// Encode packet into byte array:
  /// MAGIC (4B) | VERSION (1B) | TYPE (1B) | SEQ (2B) | LENGTH (4B) | PAYLOAD (N B) | CRC32 (4B)
  Uint8List encode() {
    final builder = BytesBuilder();
    builder.add(magic);
    builder.addByte(version);
    builder.addByte(type.index);

    // Sequence Number (2 bytes big endian)
    final seqData = ByteData(2)..setUint16(0, sequenceNumber, Endian.big);
    builder.add(seqData.buffer.asUint8List());

    // Payload Length (4 bytes big endian)
    final lenData = ByteData(4)..setUint32(0, payload.length, Endian.big);
    builder.add(lenData.buffer.asUint8List());

    builder.add(payload);

    final body = builder.toBytes();
    final checksum = calculateCrc32(body);

    final crcData = ByteData(4)..setUint32(0, checksum, Endian.big);

    final finalPacket = BytesBuilder();
    finalPacket.add(body);
    finalPacket.add(crcData.buffer.asUint8List());
    return finalPacket.toBytes();
  }

  /// Decode byte array into SoviPacket
  static SoviPacket decode(Uint8List data) {
    if (data.length < 16) {
      throw SoviException(
        code: 'PACKET_TOO_SHORT',
        userMessage: 'Corrupted acoustic packet received',
        technicalMessage: 'Byte buffer length ${data.length} < 16 min header size',
      );
    }

    // Verify Magic
    if (data[0] != magic[0] || data[1] != magic[1] || data[2] != magic[2] || data[3] != magic[3]) {
      throw SoviException(
        code: 'INVALID_MAGIC',
        userMessage: 'Invalid SOVI magic header',
        technicalMessage: 'Header bytes [${data[0]}, ${data[1]}, ${data[2]}, ${data[3]}] != USON',
      );
    }

    // Verify Version
    if (data[4] != version) {
      throw SoviException(
        code: 'UNSUPPORTED_VERSION',
        userMessage: 'Incompatible SOVI version',
        technicalMessage: 'Protocol version ${data[4]} != $version',
      );
    }

    final typeIndex = data[5];
    final type = PacketType.values[typeIndex % PacketType.values.length];

    final bd = ByteData.sublistView(data);
    final seq = bd.getUint16(6, Endian.big);
    final payloadLen = bd.getUint32(8, Endian.big);

    final expectedTotal = 12 + payloadLen + 4;
    if (data.length < expectedTotal) {
      throw SoviException(
        code: 'INCOMPLETE_PACKET',
        userMessage: 'Incomplete packet frame received',
        technicalMessage: 'Data size ${data.length} < expected $expectedTotal',
      );
    }

    final body = data.sublist(0, 12 + payloadLen);
    final receivedCrc = bd.getUint32(12 + payloadLen, Endian.big);
    final calculatedCrc = calculateCrc32(body);

    if (receivedCrc != calculatedCrc) {
      throw SoviException(
        code: 'CRC_ERROR',
        userMessage: 'Packet checksum failure',
        technicalMessage: 'CRC32 mismatch: expected $calculatedCrc, got $receivedCrc',
      );
    }

    final payload = data.sublist(12, 12 + payloadLen);
    return SoviPacket(
      type: type,
      sequenceNumber: seq,
      payload: payload,
    );
  }

  /// IEEE 802.3 Standard CRC32
  static int calculateCrc32(Uint8List data) {
    int crc = 0xFFFFFFFF;
    for (var byte in data) {
      crc ^= byte;
      for (var i = 0; i < 8; i++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xEDB88320;
        } else {
          crc = crc >> 1;
        }
      }
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }

  /// Convert byte array to bit list
  static List<int> bytesToBits(Uint8List bytes) {
    final bits = <int>[];
    for (var b in bytes) {
      for (var i = 7; i >= 0; i--) {
        bits.add((b >> i) & 1);
      }
    }
    return bits;
  }

  /// Convert bit list to byte array
  static Uint8List bitsToBytes(List<int> bits) {
    final byteCount = bits.length ~/ 8;
    final result = Uint8List(byteCount);
    for (var i = 0; i < byteCount; i++) {
      var val = 0;
      for (var b = 0; b < 8; b++) {
        val = (val << 1) | (bits[i * 8 + b] & 1);
      }
      result[i] = val;
    }
    return result;
  }
}

class PacketAssembler {
  static const int defaultChunkSize = 128; // 128 bytes per packet

  /// Split payload bytes into sequence-indexed DATA packets
  static List<SoviPacket> chunkPayload(Uint8List payload, {int chunkSize = defaultChunkSize}) {
    final packets = <SoviPacket>[];
    var seq = 0;

    for (var i = 0; i < payload.length; i += chunkSize) {
      final end = (i + chunkSize < payload.length) ? i + chunkSize : payload.length;
      final chunk = payload.sublist(i, end);

      packets.add(
        SoviPacket(
          type: PacketType.data,
          sequenceNumber: seq++,
          payload: chunk,
        ),
      );
    }

    return packets;
  }

  /// Reassemble ordered list of DATA packets into complete payload bytes
  static Uint8List reassemblePayload(List<SoviPacket> packets) {
    final sorted = List<SoviPacket>.from(packets)..sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));
    final builder = BytesBuilder();

    for (var packet in sorted) {
      if (packet.type == PacketType.data) {
        builder.add(packet.payload);
      }
    }

    return builder.toBytes();
  }
}

class ProtocolStateMachine {
  TransferStatus status = TransferStatus.idle;
  int currentSequence = 0;
  int retryCount = 0;
  int crcErrors = 0;
  int packetsRx = 0;
  int packetsTx = 0;
  int acksRx = 0;
  int nacksRx = 0;
  final List<SoviPacket> receivedPackets = [];

  /// Process incoming packet and generate appropriate ACK/NACK response
  SoviPacket? handleReceivedPacket(SoviPacket packet) {
    packetsRx++;
    switch (packet.type) {
      case PacketType.hello:
        status = TransferStatus.handshake;
        currentSequence = 0;
        ProtocolEventLogger.log('HELLO RECEIVED');
        ProtocolEventLogger.log('TRANSMITTING HELLO ACK');
        return SoviPacket.createAck(0);

      case PacketType.meta:
        status = TransferStatus.handshake;
        currentSequence = 0;
        ProtocolEventLogger.log('META RECEIVED');
        ProtocolEventLogger.log('TRANSMITTING META ACK');
        return SoviPacket.createAck(0);

      case PacketType.data:
        status = TransferStatus.transferring;
        if (packet.sequenceNumber == currentSequence) {
          receivedPackets.add(packet);
          final ackSeq = currentSequence;
          currentSequence++;
          ProtocolEventLogger.log('DATA #${packet.sequenceNumber} RECEIVED & VERIFIED');
          ProtocolEventLogger.log('TRANSMITTING ACK #$ackSeq');
          return SoviPacket.createAck(ackSeq);
        } else {
          retryCount++;
          ProtocolEventLogger.log('DATA #${packet.sequenceNumber} OUT OF ORDER (EXPECTED #$currentSequence)', isError: true);
          ProtocolEventLogger.log('TRANSMITTING NACK #$currentSequence', isError: true);
          return SoviPacket.createNack(currentSequence);
        }

      case PacketType.ack:
        acksRx++;
        ProtocolEventLogger.log('ACK #${packet.sequenceNumber} RECEIVED');
        return null;

      case PacketType.nack:
        nacksRx++;
        retryCount++;
        ProtocolEventLogger.log('NACK #${packet.sequenceNumber} RECEIVED', isError: true);
        return null;

      case PacketType.end:
        status = TransferStatus.completed;
        ProtocolEventLogger.log('END PACKET RECEIVED');
        ProtocolEventLogger.log('TRANSMITTING END ACK');
        return SoviPacket.createAck(packet.sequenceNumber);

      default:
        return null;
    }
  }
}
