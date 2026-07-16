import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/monitoring/crash_reporter.dart';
import 'core/services/app_version_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'core/utils/notification_deep_link.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/chat/controllers/chat_controller.dart';
import 'features/notifications/controllers/notification_controller.dart';
import 'features/admin/controllers/admin_bank_controller.dart';
import 'features/profile/controllers/bank_controller.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/widgets/soft_update_prompt.dart';

void main() {
  // Bindings + splash MUST be initialized inside the same Zone that calls
  // runApp — otherwise Flutter throws "Zone mismatch" and Crashlytics logs a
  // noisy false-positive at every cold start.
  runZonedGuarded(
    () async {
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
      // Khoá app ở chế độ dọc — không cho xoay ngang (cả iOS + Android).
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      // Init locale 'vi' + 'vi_VN' so DateFormat(..., 'vi') doesn't throw
      // LocaleDataException. Fast + sync — no timeout needed.
      try {
        await initializeDateFormatting('vi');
        await initializeDateFormatting('vi_VN');
      } catch (e) {
        if (kDebugMode) debugPrint('[Intl] init locale failed: $e');
      }

      // Critical init — Firebase + Crashlytics must complete before runApp to
      // catch early crashes. But DO NOT block longer than 5s (e.g. if network
      // init hangs).
      try {
        await Firebase.initializeApp().timeout(const Duration(seconds: 5));
        await CrashReporter.init().timeout(const Duration(seconds: 3));
      } catch (e) {
        if (kDebugMode) debugPrint('[Firebase] Init failed/timeout: $e');
      }

      // Push notification init runs in background — DO NOT block runApp. iOS
      // APNs registration can take 5-30s; awaiting it would stall splash.
      unawaited(_initPushInBackground());

      runApp(
        const ProviderScope(
          child: HomestayApp(),
        ),
      );
    },
    CrashReporter.record,
  );
}

Future<void> _initPushInBackground() async {
  try {
    await PushNotificationService.instance
        .initialize()
        .timeout(const Duration(seconds: 15));
  } catch (e) {
    if (kDebugMode) debugPrint('[Push] init failed/timeout: $e');
  }
}

class HomestayApp extends ConsumerStatefulWidget {
  const HomestayApp({super.key});

  @override
  ConsumerState<HomestayApp> createState() => _HomestayAppState();
}

class _HomestayAppState extends ConsumerState<HomestayApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Wire FCM notification tap → router. Defer 1 frame so router is
    // initialized and auth state is ready (in case of cold-start from a
    // notification tap).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.instance.onNotificationTap = (data) {
        // Subscription was just activated (admin reconciled the VietQR bank
        // transfer) → pull the fresh profile so the dashboard banner + route
        // guards update before we navigate.
        _maybeRefreshOnSubscriptionPush(data);

        // Admin vừa duyệt/từ chối KYC (`kyc_approved` deepLink `/dashboard`) →
        // refresh profile TRƯỚC khi điều hướng để banner "Xác thực" tự ẩn.
        _maybeRefreshOnKycPush(data);

        // BE gửi deepLink dạng path web (`/host/...`, `/my-bookings`...) không
        // khớp router app → dịch qua pushType/path sang route app (fallback
        // `/notifications` khi đích chưa có route). Resolver chỉ trả path nội bộ
        // nên vẫn an toàn open-redirect.
        final route = resolveNotificationRoute(data);
        if (route == null) return;
        ref.read(routerProvider).go(route);
      };

      // Silent foreground data push (no tap) — e.g. `subscription_paid` arrives
      // while the user waits on the payment screen → refresh profile in place;
      // chat_message → cập nhật badge chưa đọc.
      PushNotificationService.instance.onForegroundData = (data) {
        _maybeRefreshOnSubscriptionPush(data);
        _maybeRefreshOnKycPush(data);
        _maybeBumpChatBadge(data);
        _maybeRefreshOnBankPush(data);
        _maybeBumpNotificationBadge(data);
      };

      // Foreground chat push: nếu đang mở đúng conversation + socket sống thì
      // ẩn banner (WS `message:new` đã render tin) — chống trùng (rule §4.5 BE).
      PushNotificationService.instance.shouldSuppressBanner =
          _isViewingConversation;

      // Check app version against BE — if force-update, block UI immediately;
      // if soft-update, show a dismissible dialog. Run after the first frame
      // so splash is finished and we have a valid context.
      _checkAppVersion();
    });
  }

  /// pushType lấy từ `data.type` (contract BE §8.4). Fallback `pushType` cho
  /// payload cũ để an toàn khi chuyển đổi.
  String? _pushTypeOf(Map<String, dynamic> data) {
    final t = data['type'] ?? data['pushType'];
    return t is String ? t : null;
  }

  /// Refresh the signed-in user's profile when a subscription-related push
  /// arrives, so a freshly-activated plan (admin marked the VietQR transfer as
  /// paid) is reflected in `currentUserProvider` immediately. Covers the
  /// `subscription_paid` push and other `subscription_*` state changes.
  void _maybeRefreshOnSubscriptionPush(Map<String, dynamic> data) {
    final pushType = _pushTypeOf(data);
    if (pushType == null || !pushType.startsWith('subscription')) return;
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return;
    ref.read(authProvider.notifier).refreshProfile();
  }

  /// Push liên quan tài khoản nhận tiền:
  /// - OWNER: `bank_approved` / `bank_rejected` → refresh profile (badge/gate)
  ///   + invalidate bankStatusProvider để màn tài khoản ngân hàng cập nhật.
  /// - ADMIN: `bank_submitted` → invalidate queue duyệt để badge cập nhật ngay.
  void _maybeRefreshOnBankPush(Map<String, dynamic> data) {
    final pushType = _pushTypeOf(data);
    if (!ref.read(authProvider).isLoggedIn) return;
    if (pushType == 'bank_approved' || pushType == 'bank_rejected') {
      ref.read(authProvider.notifier).refreshProfile();
      ref.invalidate(bankStatusProvider);
    } else if (pushType == 'bank_submitted') {
      ref.invalidate(bankQueueProvider);
    }
  }

  /// Push KYC gửi cho OWNER khi admin thao tác duyệt hồ sơ:
  /// - `kyc_approved` → `user.kycStatus` chuyển `approved` → ẩn banner "Xác
  ///   thực danh tính", mở khoá tạo phòng (route guard).
  /// - `kyc_rejected` → cập nhật trạng thái để banner đổi sang "Bổ sung".
  /// Refresh profile ngay thay vì đọc cache cũ (nguyên nhân banner còn kẹt).
  /// `kyc_submitted` gửi ADMIN nên không xử lý ở đây.
  void _maybeRefreshOnKycPush(Map<String, dynamic> data) {
    final pushType = _pushTypeOf(data);
    if (pushType != 'kyc_approved' && pushType != 'kyc_rejected') return;
    if (!ref.read(authProvider).isLoggedIn) return;
    ref.read(authProvider.notifier).refreshProfile();
  }

  /// Chat push đến khi app foreground → refresh badge chưa đọc. WS đã lo khi
  /// socket sống, gọi thêm để chắc chắn khi socket rớt. Đọc `.notifier` cũng
  /// khởi tạo socket/unread nếu chưa có.
  void _maybeBumpChatBadge(Map<String, dynamic> data) {
    if (_pushTypeOf(data) != 'chat_message') return;
    if (!ref.read(authProvider).isLoggedIn) return;
    ref.read(chatUnreadCountProvider.notifier).refresh();
  }

  /// Push thông báo (booking/property/calendar/kyc...) đến khi app foreground →
  /// refresh badge chuông thông báo (GET /notifications/unread-count). Chat có
  /// badge riêng nên loại trừ.
  void _maybeBumpNotificationBadge(Map<String, dynamic> data) {
    final pushType = _pushTypeOf(data);
    if (pushType == null || pushType == 'chat_message') return;
    if (!ref.read(authProvider).isLoggedIn) return;
    ref.invalidate(unreadCountProvider);
  }

  /// true nếu app đang mở đúng màn conversation của tin push + socket còn sống
  /// → suppress banner foreground (rule §4.5 BE).
  bool _isViewingConversation(Map<String, dynamic> data) {
    if (_pushTypeOf(data) != 'chat_message') return false;
    final convId = _extractConversationId(data);
    if (convId == null) return false;
    if (!ref.read(chatSocketServiceProvider).isConnected) return false;
    final path =
        ref.read(routerProvider).routerDelegate.currentConfiguration.uri.path;
    return path == '/conversations/$convId';
  }

  /// Lấy conversationId từ `targetId` hoặc parse từ `deepLink` (/conversations/:id).
  String? _extractConversationId(Map<String, dynamic> data) {
    final target = data['targetId'];
    if (target is String && target.isNotEmpty) return target;
    final deepLink = data['deepLink'];
    if (deepLink is String) {
      final segs = Uri.tryParse(deepLink)?.pathSegments ?? const [];
      if (segs.length >= 2 && segs[0] == 'conversations') return segs[1];
    }
    return null;
  }

  Future<void> _checkAppVersion() async {
    final info = await AppVersionService.instance.check();
    if (!mounted) return;
    if (info.status == AppVersionStatus.upToDate ||
        info.status == AppVersionStatus.unknown) {
      return;
    }
    final ctx =
        ref.read(routerProvider).routerDelegate.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    await showAppUpdatePrompt(ctx, info: info);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app returns to foreground → refresh user profile to pick up
    // new KYC/subscription status (e.g. admin just approved while the app was
    // in background). No-op if not logged in (notifier checks).
    if (state == AppLifecycleState.resumed) {
      final auth = ref.read(authProvider);
      if (auth.isLoggedIn) {
        ref.read(authProvider.notifier).refreshProfile();
        // Khôi phục FCM token nếu lần đăng ký trước thất bại (xin quyền/getToken
        // lỗi) — no-op nếu đã có token. Giúp giảm tỉ lệ owner 0-device.
        PushNotificationService.instance.ensureRegistered();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    // Eager-connect socket chat ngay khi đã login (không chờ mở dashboard/chat)
    // → tin realtime + đồng bộ đọc/typing hoạt động ở mọi màn, và badge/thông
    // báo luôn cập nhật. Socket tự huỷ khi logout (userId null).
    if (ref.watch(authProvider.select((s) => s.isLoggedIn))) {
      ref.watch(chatSocketServiceProvider);
    }

    return MaterialApp.router(
      title: 'Halong24h',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) => GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: child,
      ),
    );
  }
}
