import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/repositories/device_repository.dart';

/// Channel ID Android — phải khớp `default_notification_channel_id` trong
/// AndroidManifest.xml.
const String _androidChannelId = 'halong24h_default';
const String _androidChannelName = 'Halong24h';
const String _androidChannelDesc =
    'Thông báo booking, thanh toán, KYC và cập nhật từ Halong24h';

/// Background message handler — phải là top-level function (yêu cầu của FCM).
/// Chạy trong isolate riêng → không truy cập được state hiện tại.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background: chỉ log. iOS tự hiện banner từ payload `notification.*`.
  // Android cũng tự hiện vì có default channel + payload `notification.*`.
  if (kDebugMode) {
    debugPrint('[FCM] Background message: ${message.messageId}');
  }
}

/// Service singleton handle FCM lifecycle: permission, token, listeners.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final DeviceRepository _deviceRepo = DeviceRepository();

  /// Token hiện tại — cache để gọi unregister khi logout.
  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  /// Callback do app set để xử lý deep link từ notification (vd
  /// `context.go(deepLink)`). Set 1 lần ở widget root.
  void Function(Map<String, dynamic> data)? onNotificationTap;

  /// Gọi 1 lần lúc app khởi động (sau khi `Firebase.initializeApp`).
  /// **KHÔNG** request permission ở đây — chỉ setup listeners. Permission xin
  /// sau khi user login để UX không hỏi quyền ngay launch.
  Future<void> initialize() async {
    // Background handler — phải set trước mọi thứ.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Local notification plugin — dùng để hiện banner khi app foreground.
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

    // Tạo Android channel (Android 8+).
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

    // Foreground: tự hiện banner qua flutter_local_notifications.
    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Tap notification (background → foreground).
    _openedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedApp);

    // Cold start: app mở từ tap notification.
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      // Defer 1 frame để router/auth state init xong.
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleTapData(initialMessage.data);
      });
    }
  }

  /// Gọi sau khi user login — xin permission, lấy token, gửi BE.
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

    // iOS: cần APNs token trước khi getToken (Firebase tự handle, nhưng có
    // edge case ở simulator). Try-catch để không crash app.
    try {
      final token = await _fcm.getToken();
      if (token == null) {
        if (kDebugMode) debugPrint('[FCM] getToken returned null');
        return;
      }
      _currentToken = token;
      await _registerTokenWithBackend(token);

      // Listen token refresh (FCM định kỳ rotate).
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _fcm.onTokenRefresh.listen((newToken) async {
        _currentToken = newToken;
        await _registerTokenWithBackend(newToken);
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] getToken failed: $e');
    }
  }

  /// Gọi trước khi logout — unregister token khỏi BE.
  Future<void> unregisterForUser() async {
    final token = _currentToken;
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    if (token != null) {
      await _deviceRepo.unregister(token);
    }
    // Xoá token local — lần login tiếp theo sẽ get token mới.
    try {
      await _fcm.deleteToken();
    } catch (_) {}
    _currentToken = null;
  }

  /// Cleanup khi app dispose (rất hiếm, chỉ trong test).
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

    // Hiện banner local — chỉ khi có nội dung. Background sẽ tự hiện qua
    // hệ thống, không cần xử lý.
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
    final callback = onNotificationTap;
    if (callback == null) return;
    callback(data);
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
