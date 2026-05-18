import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/repositories/device_repository.dart';

/// Android channel ID — must match `default_notification_channel_id` in
/// AndroidManifest.xml.
const String _androidChannelId = 'halong24h_default';
const String _androidChannelName = 'Halong24h';
const String _androidChannelDesc =
    'Thông báo booking, thanh toán, KYC và cập nhật từ Halong24h';

/// Background message handler — must be a top-level function (FCM requirement).
/// Runs in a separate isolate → cannot access current state.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background: just log. iOS auto-shows banner from `notification.*` payload.
  // Android also auto-shows because of default channel + `notification.*`.
  if (kDebugMode) {
    debugPrint('[FCM] Background message: ${message.messageId}');
  }
}

/// Singleton service handling FCM lifecycle: permission, token, listeners.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final DeviceRepository _deviceRepo = DeviceRepository();

  /// Current token — cached so we can call unregister on logout.
  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  /// Callback set by the app to handle deep links from notifications (e.g.
  /// `context.go(deepLink)`). Set once at the widget root.
  void Function(Map<String, dynamic> data)? onNotificationTap;

  /// Called once at app startup (after `Firebase.initializeApp`).
  /// Does **NOT** request permission here — only sets up listeners. Permission
  /// is requested after the user logs in so the OS prompt doesn't appear on
  /// the very first launch.
  Future<void> initialize() async {
    // Background handler — must be set before anything else.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Local notification plugin — used to show banners while in foreground.
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _handleTapData(_parsePayload(payload));
      },
    );

    // Create Android channel (Android 8+).
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: _androidChannelDesc,
        importance: Importance.high,
      ),
    );

    // Foreground: show banners ourselves via flutter_local_notifications.
    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Tap notification (background → foreground).
    _openedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedApp);

    // Cold start: app opened by tapping a notification.
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      // Defer 1 frame so router/auth state are initialized.
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleTapData(initialMessage.data);
      });
    }
  }

  /// Call after user login — request permission, get token, send to BE.
  /// Idempotent.
  Future<void> registerForUser() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (kDebugMode) debugPrint('[FCM] User denied notification permission');
      return;
    }

    // iOS: needs APNs token before getToken (Firebase handles this, but there
    // are edge cases on the simulator). Try-catch to avoid crashing the app.
    try {
      final token = await _fcm.getToken();
      if (token == null) {
        if (kDebugMode) debugPrint('[FCM] getToken returned null');
        return;
      }
      _currentToken = token;
      await _registerTokenWithBackend(token);

      // Listen for token refresh (FCM rotates periodically).
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _fcm.onTokenRefresh.listen((newToken) async {
        _currentToken = newToken;
        await _registerTokenWithBackend(newToken);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] getToken failed: $e');
    }
  }

  /// Call before logout — unregister the token from BE.
  Future<void> unregisterForUser() async {
    final token = _currentToken;
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    if (token != null) {
      await _deviceRepo.unregister(token);
    }
    // Delete local token — next login will fetch a fresh one.
    try {
      await _fcm.deleteToken();
    } catch (_) {}
    _currentToken = null;
  }

  /// Cleanup on app dispose (rare, mostly used in tests).
  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
    _openedAppSub?.cancel();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _registerTokenWithBackend(String token) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    await _deviceRepo.register(
      fcmToken: token,
      platform: platform,
      locale: 'vi',
    );
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Show local banner — only when there is content. Background banners are
    // shown by the OS automatically; no work needed here.
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: _encodePayload(message.data),
    );
  }

  void _onOpenedApp(RemoteMessage message) {
    _handleTapData(message.data);
  }

  void _handleTapData(Map<String, dynamic> data) {
    if (onNotificationTap == null) return;
    onNotificationTap!(data);
  }

  String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  Map<String, dynamic> _parsePayload(String payload) {
    final result = <String, dynamic>{};
    for (final pair in payload.split('&')) {
      final idx = pair.indexOf('=');
      if (idx < 0) continue;
      result[pair.substring(0, idx)] = pair.substring(idx + 1);
    }
    return result;
  }
}
