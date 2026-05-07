import 'dart:developer';

class AnalyticsService {
  static void logEvent(
    String name, {
    Map<String, Object?> params = const {},
  }) {
    log(
      'event=$name params=$params',
      name: 'Analytics',
    );
  }
}
