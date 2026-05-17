import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';

/// Lấy device ID stable cho header `X-Device-Id` (BE anti-spam ở
/// `/auth/register` và `/auth/google`).
///
/// - iOS: `identifierForVendor` — UUID, reset khi user uninstall mọi app cùng vendor
/// - Android: `id` (SSAID) — UUID per app+device, reset khi factory reset
class DeviceIdService {
  DeviceIdService._();
  static final DeviceIdService instance = DeviceIdService._();

  String? _cachedId;

  /// Trả về device ID. Cache trong memory để tránh gọi plugin nhiều lần.
  /// Trả về `null` nếu không lấy được — caller bỏ header (BE fallback IP).
  Future<String?> getDeviceId() async {
    if (_cachedId != null) return _cachedId;

    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        _cachedId = info.identifierForVendor;
      } else if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        _cachedId = info.id;
      }
      return _cachedId;
    } catch (_) {
      return null;
    }
  }
}
