import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  /// Đăng ký lại token khi app resume NẾU chưa có (khôi phục trường hợp lần
  /// trước xin quyền/getToken thất bại). No-op nếu đã có token → tránh spam
  /// POST /devices mỗi lần foreground.
  Future<void> ensureRegistered() async {
    if (_currentToken != null) return;
    await registerForUser();
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

    // iOS: getToken() cần APNs token có trước, nếu không sẽ trả null (nguyên
    // nhân 0 token iOS). Sau requestPermission, APNs token có thể chưa sẵn ngay
    // → chờ/retry vài giây trước khi getToken.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        var apns = await _fcm.getAPNSToken();
        // APNs token về bất đồng bộ sau khi iOS đăng ký với Apple; mạng chậm có
        // thể mất vài giây → chờ tối đa ~10s. Nếu vẫn null (mạng chặn APNs /
        // provisioning thiếu Push) thì ensureRegistered() sẽ thử lại lần resume.
        for (var i = 0; i < 10 && apns == null; i++) {
          await Future.delayed(const Duration(seconds: 1));
          apns = await _fcm.getAPNSToken();
        }
        if (apns == null && kDebugMode) {
          debugPrint('[FCM] APNs token vẫn null sau 10s — mạng chặn APNs hoặc '
              'thiếu Push capability trên provisioning');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[FCM] getAPNSToken failed: $e');
      }
    }

    try {
      final token = await _fcm.getToken();
      if (token == null) {
        if (kDebugMode) debugPrint('[FCM] getToken returned null');
        return;
      }
      _currentToken = token;
      if (kDebugMode) debugPrint('[FCM] token: $token'); // copy để test push
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
    // Best-effort metadata (BE §20.2) — không chặn đăng ký token nếu thất bại.
    String? deviceModel;
    String? osVersion;
    String? appVersion;
    try {
      appVersion = (await PackageInfo.fromPlatform()).version;
      final info = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = await info.iosInfo;
        deviceModel = ios.utsname.machine; // vd iPhone16,2
        osVersion = 'iOS ${ios.systemVersion}';
      } else {
        final android = await info.androidInfo;
        deviceModel = '${android.manufacturer} ${android.model}';
        osVersion = 'Android ${android.version.release}';
      }
    } catch (_) {
      // thiếu metadata vẫn đăng ký token bình thường
    }

    await _deviceRepo.register(
      fcmToken: token,
      platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      deviceModel: deviceModel,
      osVersion: osVersion,
      appVersion: appVersion,
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
