import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TransferRecord {
  final String id;
  final String direction; // 'sent' or 'received'
  final String type; // 'file' or 'text'
  final String status; // 'success', 'failed', 'cancelled', 'timeout'
  final String fileName;
  final int fileSize;
  final int packetsSent;
  final int packetsReceived;
  final int acks;
  final int nacks;
  final int retries;
  final int crcErrors;
  final int durationSeconds;
  final int throughputBps;
  final DateTime timestamp;
  final String? originalSha256;
  final String? receivedSha256;
  final String? errorCode;
  final String? errorMessage;
  final String? textContent;

  TransferRecord({
    required this.id,
    required this.direction,
    required this.type,
    required this.status,
    required this.fileName,
    required this.fileSize,
    required this.packetsSent,
    required this.packetsReceived,
    required this.acks,
    required this.nacks,
    required this.retries,
    required this.crcErrors,
    required this.durationSeconds,
    required this.throughputBps,
    required this.timestamp,
    this.originalSha256,
    this.receivedSha256,
    this.errorCode,
    this.errorMessage,
    this.textContent,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'direction': direction,
        'type': type,
        'status': status,
        'fileName': fileName,
        'fileSize': fileSize,
        'packetsSent': packetsSent,
        'packetsReceived': packetsReceived,
        'acks': acks,
        'nacks': nacks,
        'retries': retries,
        'crcErrors': crcErrors,
        'durationSeconds': durationSeconds,
        'throughputBps': throughputBps,
        'timestamp': timestamp.toIso8601String(),
        'originalSha256': originalSha256,
        'receivedSha256': receivedSha256,
        'errorCode': errorCode,
        'errorMessage': errorMessage,
        'textContent': textContent,
      };

  factory TransferRecord.fromJson(Map<String, dynamic> json) => TransferRecord(
        id: json['id'],
        direction: json['direction'],
        type: json['type'] ?? 'file',
        status: json['status'] ?? (json['isSuccess'] == true ? 'success' : 'failed'),
        fileName: json['fileName'],
        fileSize: json['fileSize'],
        packetsSent: json['packetsSent'] ?? json['packetCount'] ?? 0,
        packetsReceived: json['packetsReceived'] ?? 0,
        acks: json['acks'] ?? 0,
        nacks: json['nacks'] ?? 0,
        retries: json['retries'] ?? json['retryCount'] ?? 0,
        crcErrors: json['crcErrors'] ?? 0,
        durationSeconds: json['durationSeconds'] ?? 0,
        throughputBps: json['throughputBps'] ?? 0,
        timestamp: DateTime.parse(json['timestamp']),
        originalSha256: json['originalSha256'],
        receivedSha256: json['receivedSha256'],
        errorCode: json['errorCode'],
        errorMessage: json['errorMessage'],
        textContent: json['textContent'],
      );
}

class HistoryRepository {
  static const String _storageKey = 'sovi_transfer_history';

  /// Get transfer history. Fresh installation starts strictly with EMPTY list []
  static Future<List<TransferRecord>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey) ?? [];
    return rawList
        .map((item) => TransferRecord.fromJson(jsonDecode(item)))
        .toList();
  }

  /// Add new real transfer record
  static Future<void> addRecord(TransferRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getHistory();
    current.insert(0, record);
    final jsonList = current.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }

  /// Clear all history
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
