import 'dart:developer';

import 'package:flutter/foundation.dart';

class CrashReporter {
  static bool _initialized = false;

  static void init() {
    if (_initialized) {
      return;
    }
    _initialized = true;

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _record(
        'FlutterError',
        details.exception,
        details.stack,
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _record('PlatformDispatcher', error, stack);
      return true;
    };
  }

  static void record(Object error, StackTrace stackTrace) {
    _record('Zone', error, stackTrace);
  }

  static void _record(String source, Object error, StackTrace? stackTrace) {
    log(
      '[$source] $error',
      name: 'CrashReporter',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
