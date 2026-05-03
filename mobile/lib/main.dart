import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'shared/providers/theme_provider.dart';

void main() {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(
    const ProviderScope(
      child: HomestayApp(),
    ),
  );
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
      title: 'Homestay Manager',
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
