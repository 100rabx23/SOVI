import 'dart:math';

class DeviceInfoService {
  static String? _cachedDeviceId;
  static String? _cachedDisplayName;

  /// Get persistent unique Device ID (e.g. SOVI-7A3F92)
  static String get deviceId {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    _cachedDeviceId = generateDeviceId();
    return _cachedDeviceId!;
  }

  /// Get device display name
  static String get displayName {
    if (_cachedDisplayName != null) return _cachedDisplayName!;
    _cachedDisplayName = "Saurabh's Phone";
    return _cachedDisplayName!;
  }

  /// Generate deterministic or random 6-character hex Device ID with SOVI- prefix
  static String generateDeviceId() {
    final rnd = Random();
    const chars = '0123456789ABCDEF';
    final suffix = List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
    return 'SOVI-$suffix';
  }

  static void setCustomDisplayName(String name) {
    _cachedDisplayName = name;
  }
}
