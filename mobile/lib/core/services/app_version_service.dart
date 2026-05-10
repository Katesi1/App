import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/api_constants.dart';
import '../network/api_client.dart';

/// Status sau khi check version với BE.
enum AppVersionStatus {
  upToDate,         // version hiện tại OK
  softUpdate,       // có version mới nhưng chưa bắt buộc
  forceUpdate,      // version hiện tại < minSupported → block
  unknown,          // không gọi được BE → bỏ qua
}

class AppVersionInfo {
  final AppVersionStatus status;
  final String currentVersion;     // build hiện tại của app (vd "1.0.2")
  final String? latestVersion;     // version mới nhất BE biết
  final String? minSupportedVersion;
  final String? releaseNotes;
  final String? storeUrl;          // URL App Store / Play Store theo platform

  const AppVersionInfo({
    required this.status,
    required this.currentVersion,
    this.latestVersion,
    this.minSupportedVersion,
    this.releaseNotes,
    this.storeUrl,
  });

  static const AppVersionInfo unknown = AppVersionInfo(
    status: AppVersionStatus.unknown,
    currentVersion: '0.0.0',
  );
}

/// Gọi `/app/version` để check force/soft update. Tách thành service riêng để
/// dễ mock trong test + invoke từ main.dart trước routing.
class AppVersionService {
  AppVersionService._();
  static final AppVersionService instance = AppVersionService._();

  final Dio _dio = ApiClient.instance;

  /// Trả về status. Lỗi network → [AppVersionStatus.unknown] (đừng block app
  /// vì BE down).
  Future<AppVersionInfo> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;
      final platform = Platform.isIOS ? 'ios' : 'android';

      final response = await _dio.get(
        ApiConstants.appVersion,
        queryParameters: {
          'platform': platform,
          'currentVersion': currentVersion,
        },
        options: Options(
          // Không gắn auth token (endpoint phải public).
          headers: {'Authorization': null},
          // Time out nhanh để không delay startup quá lâu.
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      final data = response.data['data'];
      if (data is! Map<String, dynamic>) {
        return AppVersionInfo(
          status: AppVersionStatus.unknown,
          currentVersion: currentVersion,
        );
      }

      final latest = data['latestVersion'] as String?;
      final minSupported = data['minSupportedVersion'] as String?;
      final releaseNotes = data['releaseNotes'] as String?;
      final storeUrls = data['storeUrl'];
      String? storeUrl;
      if (storeUrls is Map) {
        storeUrl = storeUrls[platform] as String?;
      }

      AppVersionStatus status = AppVersionStatus.upToDate;
      if (minSupported != null &&
          _compare(currentVersion, minSupported) < 0) {
        status = AppVersionStatus.forceUpdate;
      } else if (latest != null && _compare(currentVersion, latest) < 0) {
        status = AppVersionStatus.softUpdate;
      }

      return AppVersionInfo(
        status: status,
        currentVersion: currentVersion,
        latestVersion: latest,
        minSupportedVersion: minSupported,
        releaseNotes: releaseNotes,
        storeUrl: storeUrl,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[AppVersion] check failed: $e');
      try {
        final info = await PackageInfo.fromPlatform();
        return AppVersionInfo(
          status: AppVersionStatus.unknown,
          currentVersion: info.version,
        );
      } catch (_) {
        return AppVersionInfo.unknown;
      }
    }
  }

  /// So sánh semver-like (`1.2.3`). Trả -1, 0, 1.
  /// Bỏ qua build metadata sau `+`. Phần thiếu coi là 0.
  int _compare(String a, String b) {
    int parse(String segment) =>
        int.tryParse(segment.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    final partsA = a.split('+').first.split('.').map(parse).toList();
    final partsB = b.split('+').first.split('.').map(parse).toList();
    final maxLen =
        partsA.length > partsB.length ? partsA.length : partsB.length;

    for (int i = 0; i < maxLen; i++) {
      final av = i < partsA.length ? partsA[i] : 0;
      final bv = i < partsB.length ? partsB[i] : 0;
      if (av < bv) return -1;
      if (av > bv) return 1;
    }
    return 0;
  }
}
