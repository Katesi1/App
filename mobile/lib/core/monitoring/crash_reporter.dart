import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crash reporting wrapper. Forward FlutterError + PlatformDispatcher errors
/// + manual `record()` từ runZonedGuarded sang Firebase Crashlytics.
///
/// Tắt Crashlytics ở debug mode để không spam dashboard với crash dev.
class CrashReporter {
  static bool _initialized = false;
  static bool _crashlyticsEnabled = false;

  /// Gọi 1 lần ở `main()` SAU khi `Firebase.initializeApp()`.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Gắn handler bất kể Crashlytics có sẵn sàng hay không.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _record('FlutterError', details.exception, details.stack);
      if (_crashlyticsEnabled) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _record('PlatformDispatcher', error, stack);
      if (_crashlyticsEnabled) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      return true;
    };

    // Crashlytics chỉ enable ở release/profile. Debug = false để dev không
    // gửi crash thật lên dashboard.
    try {
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
      _crashlyticsEnabled = !kDebugMode;
    } catch (e) {
      if (kDebugMode) debugPrint('[Crashlytics] init failed: $e');
    }
  }

  /// Gọi từ runZonedGuarded — async error ngoài Flutter framework.
  static void record(Object error, StackTrace stackTrace) {
    _record('Zone', error, stackTrace);
    if (_crashlyticsEnabled) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    }
  }

  /// Set user ID + email cho Crashlytics — gọi sau login để link crash với
  /// user. KHÔNG gửi PII nhạy cảm (chỉ user.id, không gửi email/phone).
  static Future<void> setUserId(String? userId) async {
    if (!_crashlyticsEnabled) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');
    } catch (_) {}
  }

  /// Log breadcrumb — context cho crash (vd "tapped login button").
  static Future<void> log(String message) async {
    if (kDebugMode) debugPrint('[CrashReporter] $message');
    if (!_crashlyticsEnabled) return;
    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (_) {}
  }

  static void _record(String source, Object error, StackTrace? stackTrace) {
    if (kDebugMode) {
      debugPrint('[CrashReporter] $source: $error\n$stackTrace');
    }
  }
}
