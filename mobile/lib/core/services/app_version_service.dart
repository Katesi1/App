import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/api_constants.dart';
import '../network/api_client.dart';

/// Status returned after checking version against BE.
enum AppVersionStatus {
  upToDate,         // current version is OK
  softUpdate,       // newer version available, not required
  forceUpdate,      // current version < minSupported → block
  unknown,          // BE unreachable → skip
}

class AppVersionInfo {
  final AppVersionStatus status;
  final String currentVersion;     // current build of the app (e.g. "1.0.2")
  final String? latestVersion;     // latest version BE knows about
  final String? minSupportedVersion;
  final String? releaseNotes;
  final String? storeUrl;          // App Store URL

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

/// Calls `/app/version` to check for force/soft update. Extracted into its own
/// service so it can be mocked in tests and invoked from main.dart before
/// routing.
class AppVersionService {
  AppVersionService._();
  static final AppVersionService instance = AppVersionService._();

  final Dio _dio = ApiClient.instance;

  /// Returns the status. Network error → [AppVersionStatus.unknown] (don't
  /// block the app just because BE is down).
  Future<AppVersionInfo> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      final response = await _dio.get(
        ApiConstants.appVersion,
        queryParameters: {
          'platform': 'ios',
          'currentVersion': currentVersion,
        },
        options: Options(
          // Don't attach auth token (endpoint must be public).
          headers: {'Authorization': null},
          // Short timeout so we don't delay startup too long.
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
        storeUrl = storeUrls['ios'] as String?;
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

  /// Compare semver-like (`1.2.3`). Returns -1, 0, 1.
  /// Ignores build metadata after `+`. Missing segments are treated as 0.
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
