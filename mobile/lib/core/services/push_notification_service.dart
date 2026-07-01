import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/repositories/device_repository.dart';

/// Local channel ID for foreground banners.
const String _channelId = 'halong24h_default';
const String _channelName = 'Halong24h';
const String _channelDesc =
    'Thông báo booking, thanh toán, KYC và cập nhật từ Halong24h';

/// Background message handler — must be a top-level function (FCM requirement).
/// Runs in a separate isolate → cannot access current state.
///
/// Push chuẩn của BE (chat, booking...) đã có `notification` block → OS tự hiện
/// tray khi app nền/killed; ta `return` sớm để KHÔNG hiện trùng. Handler này chỉ
/// là lưới an toàn cho push **data-only** (không có `notification` block) — tự
/// dựng local notification để vẫn có thông báo khi user không mở app.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('[FCM] Background message: ${message.messageId}');
  }
  if (message.notification != null) return; // OS tự hiện — tránh trùng.

  final data = message.data;
  final title = data['title'] as String?;
  final body = (data['subtitle'] ?? data['body']) as String?;
  if (title == null && body == null) return; // silent push (vd refresh) → bỏ.

  // Isolate nền: khởi tạo plugin riêng rồi show. AndroidNotificationDetails tự
  // tạo channel nếu chưa có.
  final local = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await local.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
  );
  await local.show(
    message.hashCode,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
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
    payload: data.entries.map((e) => '${e.key}=${e.value}').join('&'),
  );
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

  /// Callback for data messages received while the app is in the FOREGROUND
  /// (no tap required). Set once at the widget root. Used to react to silent
  /// state-change pushes — e.g. `pushType=subscription_paid` → refresh the user
  /// profile so the just-activated subscription shows up immediately.
  void Function(Map<String, dynamic> data)? onForegroundData;

  /// Return `true` to suppress the foreground banner for this data payload —
  /// e.g. một tin nhắn chat của đúng conversation user đang mở (WS `message:new`
  /// đã render trong thread rồi). Set once at the widget root. KHÔNG ảnh hưởng
  /// [onForegroundData] (vẫn chạy để cập nhật badge/state).
  bool Function(Map<String, dynamic> data)? shouldSuppressBanner;

  /// Called once at app startup (after `Firebase.initializeApp`).
  /// Does **NOT** request permission here — only sets up listeners. Permission
  /// is requested after the user logs in so the OS prompt doesn't appear on
  /// the very first launch.
  Future<void> initialize() async {
    // Background handler — must be set before anything else.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Local notification plugin — used to show banners while in foreground.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
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

    // Plugin requires a channel registration (no-op on iOS at runtime).
    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );

    // Foreground: show banners ourselves via flutter_local_notifications.
    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // Tap notification (background → foreground).
    _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedApp);

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

  /// Coerce an FCM data-map value to a String without throwing on odd types.
  static String? _asString(Object? v) => v is String ? v : v?.toString();

  Future<void> _registerTokenWithBackend(String token) async {
    await _deviceRepo.register(
      fcmToken: token,
      platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      locale: 'vi',
    );
  }

  void _onForegroundMessage(RemoteMessage message) {
    // Surface data-only messages (BE sends data-messages per API spec §8.4) to
    // the app so it can react silently — e.g. refresh profile on
    // `subscription_paid`. Runs regardless of whether a banner is shown.
    if (message.data.isNotEmpty) {
      onForegroundData?.call(message.data);
    }

    final notification = message.notification;
    // Data-only push (no `notification` block) → fall back to title/subtitle in
    // the data payload so the user still sees a banner (e.g. "Thanh toán thành công").
    // Read defensively: FCM data values are strings by contract, but never crash
    // the stream handler if the backend ever sends a non-string value.
    final title = notification?.title ?? _asString(message.data['title']);
    final body = notification?.body ??
        _asString(message.data['subtitle'] ?? message.data['body']);
    if (title == null && body == null) return;

    // Chống trùng: nếu đang xem đúng conversation + socket sống → WS đã render
    // tin rồi, không hiện banner (rule §4.5 BE). onForegroundData ở trên vẫn đã
    // chạy để cập nhật badge khi cần.
    if (shouldSuppressBanner?.call(message.data) == true) return;

    // Show local banner — only when there is content. Background banners are
    // shown by the OS automatically; no work needed here.
    _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
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
