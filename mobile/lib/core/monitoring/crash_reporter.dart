import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crash reporting wrapper. Forwards FlutterError + PlatformDispatcher errors
/// + manual `record()` from runZonedGuarded to Firebase Crashlytics.
///
/// Crashlytics is disabled in debug mode to avoid spamming the dashboard with
/// dev crashes.
class CrashReporter {
  static bool _initialized = false;
  static bool _crashlyticsEnabled = false;

  /// Call once in `main()` AFTER `Firebase.initializeApp()`.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Attach handlers regardless of whether Crashlytics is ready.
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

    // Crashlytics is only enabled in release/profile. Debug = false so devs
    // don't ship real crashes to the dashboard.
    try {
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
      _crashlyticsEnabled = !kDebugMode;
    } catch (e) {
      if (kDebugMode) debugPrint('[Crashlytics] init failed: $e');
    }
  }

  /// Called from runZonedGuarded — async errors outside the Flutter framework.
  static void record(Object error, StackTrace stackTrace) {
    _record('Zone', error, stackTrace);
    if (_crashlyticsEnabled) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    }
  }

  /// Set user ID for Crashlytics — call after login to link crashes with the
  /// user. Do NOT send sensitive PII (only user.id; never email/phone).
  static Future<void> setUserId(String? userId) async {
    if (!_crashlyticsEnabled) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');
    } catch (_) {}
  }

  /// Log a breadcrumb — context for a crash (e.g. "tapped login button").
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
