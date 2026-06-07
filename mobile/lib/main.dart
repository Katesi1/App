import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/monitoring/crash_reporter.dart';
import 'core/services/app_version_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'features/auth/controllers/auth_controller.dart';
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

        final deepLink = data['deepLink'];
        if (deepLink is! String || deepLink.isEmpty) return;
        final uri = Uri.tryParse(deepLink);
        if (uri == null) return;
        // Only allow relative paths (no scheme/host) to prevent open
        // redirects from spoofed notifications.
        if (uri.hasScheme || uri.hasAuthority) return;
        ref.read(routerProvider).go(deepLink);
      };

      // Silent foreground data push (no tap) — e.g. `subscription_paid` arrives
      // while the user waits on the payment screen → refresh profile in place.
      PushNotificationService.instance.onForegroundData = (data) {
        _maybeRefreshOnSubscriptionPush(data);
      };

      // Check app version against BE — if force-update, block UI immediately;
      // if soft-update, show a dismissible dialog. Run after the first frame
      // so splash is finished and we have a valid context.
      _checkAppVersion();
    });
  }

  /// Refresh the signed-in user's profile when a subscription-related push
  /// arrives, so a freshly-activated plan (admin marked the VietQR transfer as
  /// paid) is reflected in `currentUserProvider` immediately. Covers the
  /// `subscription_paid` push and other `subscription_*` state changes.
  void _maybeRefreshOnSubscriptionPush(Map<String, dynamic> data) {
    final pushType = data['pushType'];
    if (pushType is! String || !pushType.startsWith('subscription')) return;
    final auth = ref.read(authProvider);
    if (!auth.isLoggedIn) return;
    ref.read(authProvider.notifier).refreshProfile();
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
      }
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
