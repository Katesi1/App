import 'package:device_info_plus/device_info_plus.dart';

/// Returns a stable device ID for the `X-Device-Id` header (BE anti-spam on
/// `/auth/register` and `/auth/google`).
///
/// Uses `identifierForVendor` (UUID that resets only when the user uninstalls
/// every app from the same vendor).
class DeviceIdService {
  DeviceIdService._();
  static final DeviceIdService instance = DeviceIdService._();

  String? _cachedId;

  /// Returns the device ID. Cached in memory to avoid calling the plugin
  /// repeatedly. Returns `null` if unavailable — caller drops the header (BE
  /// falls back to IP).
  Future<String?> getDeviceId() async {
    if (_cachedId != null) return _cachedId;

    try {
      final plugin = DeviceInfoPlugin();
      final info = await plugin.iosInfo;
      _cachedId = info.identifierForVendor;
      return _cachedId;
    } catch (_) {
      return null;
    }
  }
}
