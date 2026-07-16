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
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/controllers/auth_controller.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/providers/view_mode_provider.dart';
import 'shared/widgets/soft_update_prompt.dart';

void main() {
  runZonedGuarded(
    () async {
      // ensureInitialized + FlutterNativeSplash phải trong cùng zone với
      // runApp để tránh "Zone mismatch" crash.
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Init locale 'vi' + 'vi_VN' để DateFormat(..., 'vi') không throw
      // LocaleDataException. Fast + sync — không cần timeout.
      try {
        await initializeDateFormatting('vi');
        await initializeDateFormatting('vi_VN');
      } catch (e) {
        if (kDebugMode) debugPrint('[Intl] init locale failed: $e');
      }

      // Critical init — Firebase + Crashlytics phải xong trước runApp để bắt
      // crash sớm. Nhưng KHÔNG để stuck quá 5s (vd network init treo).
      try {
        await Firebase.initializeApp()
            .timeout(const Duration(seconds: 5));
        await CrashReporter.init().timeout(const Duration(seconds: 3));
      } catch (e) {
        if (kDebugMode) debugPrint('[Firebase] Init failed/timeout: $e');
      }

      // SharedPreferences phải load xong trước runApp để ViewModeNotifier
      // đọc synchronously, tránh redirect flash do async load gây ra.
      final prefs = await SharedPreferences.getInstance();

      // Push notification init chạy nền — KHÔNG block runApp. iOS APNs
      // registration có thể mất 5-30s, nếu await sẽ stuck splash.
      unawaited(_initPushInBackground());

      runApp(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const HomestayApp(),
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

    // Wire FCM notification tap → router. Defer 1 frame để router init xong
    // và auth state ready (nếu cold-start từ tap notification).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.instance.onNotificationTap = (data) {
        final deepLink = data['deepLink'];
        if (deepLink is! String || deepLink.isEmpty) return;
        final uri = Uri.tryParse(deepLink);
        if (uri == null) return;
        // Chỉ cho phép relative path (không có scheme/host) để tránh
        // open redirect từ notification bị giả mạo.
        if (uri.hasScheme || uri.hasAuthority) return;
        ref.read(routerProvider).go(deepLink);
      };

      // Check app version với BE — nếu force-update thì block UI ngay,
      // soft-update thì hiện dialog dismissible. Run sau frame đầu để
      // splash xong + có context hợp lệ.
      _checkAppVersion();
    });
  }

  Future<void> _checkAppVersion() async {
    final info = await AppVersionService.instance.check();
    if (!mounted) return;
    if (info.status == AppVersionStatus.upToDate ||
        info.status == AppVersionStatus.unknown) {
      return;
    }
    final ctx = ref.read(routerProvider).routerDelegate.navigatorKey
        .currentContext;
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
    // Khi app foreground lại → refresh user profile để bắt KYC/subscription
    // status mới (vd admin vừa approve trong khi app đang ở background).
    // No-op nếu chưa login (notifier check).
    if (state == AppLifecycleState.resumed) {
      // Throttle 30s tập trung trong AuthNotifier — dùng chung với auto-refresh
      // khi vào dashboard, tránh double-fetch nếu resume rơi trúng dashboard.
      unawaited(ref.read(authProvider.notifier).refreshProfileIfStale());
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

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
