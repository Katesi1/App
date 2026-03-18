import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/screens/user_form_screen.dart';
import '../../features/admin/screens/user_list_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/bookings/screens/booking_list_screen.dart';
import '../../features/bookings/screens/hold_room_screen.dart';
import '../../features/homestays/screens/homestay_form_screen.dart';
import '../../features/homestays/screens/homestay_list_screen.dart';
import '../../features/rooms/screens/room_calendar_screen.dart';
import '../../features/rooms/screens/room_detail_screen.dart';
import '../../features/rooms/screens/room_form_screen.dart';
import '../../features/rooms/screens/room_images_screen.dart';
import '../../features/rooms/screens/room_list_screen.dart';
import '../../features/rooms/screens/room_price_screen.dart';
import '../../shared/providers/auth_provider.dart';
import 'app_transitions.dart';

// Notifier giúp GoRouter biết khi nào cần re-evaluate redirect.
// Khi authProvider thay đổi → notifyListeners() → GoRouter chạy lại redirect.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isLoggedIn;
      final isLoading = authState.isLoading;
      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';

      if (isLoading) return isSplash ? null : '/splash';
      if (!isLoggedIn && !isLogin) return '/login';
      if (isLoggedIn && (isLogin || isSplash)) return '/rooms';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      // ── Rooms ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/rooms',
        pageBuilder: (_, state) => horizontalPage(
          key: state.pageKey,
          child: const RoomListScreen(),
        ),
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (_, state) => slideUpPage(
              key: state.pageKey,
              child: RoomDetailScreen(roomId: state.pathParameters['id']!),
            ),
            routes: [
              GoRoute(
                path: 'calendar',
                pageBuilder: (_, state) => slideUpPage(
                  key: state.pageKey,
                  child:
                      RoomCalendarScreen(roomId: state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'hold',
                pageBuilder: (_, state) => fadeScalePage(
                  key: state.pageKey,
                  child: HoldRoomScreen(roomId: state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'images',
                pageBuilder: (_, state) => slideUpPage(
                  key: state.pageKey,
                  child: RoomImagesScreen(roomId: state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'price',
                pageBuilder: (_, state) => slideUpPage(
                  key: state.pageKey,
                  child: RoomPriceScreen(roomId: state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'edit',
                pageBuilder: (_, state) => fadeScalePage(
                  key: state.pageKey,
                  child: RoomFormScreen(roomId: state.pathParameters['id']),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'new',
            pageBuilder: (_, state) => fadeScalePage(
              key: state.pageKey,
              child: RoomFormScreen(
                homestayId: state.uri.queryParameters['homestayId'],
              ),
            ),
          ),
        ],
      ),

      // ── Bookings ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/bookings',
        pageBuilder: (_, state) => horizontalPage(
          key: state.pageKey,
          child: const BookingListScreen(),
        ),
      ),

      // ── Homestays (Owner/Admin) ────────────────────────────────────────────
      GoRoute(
        path: '/homestays',
        pageBuilder: (_, state) => horizontalPage(
          key: state.pageKey,
          child: const HomestayListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'new',
            pageBuilder: (_, state) => fadeScalePage(
              key: state.pageKey,
              child: const HomestayFormScreen(),
            ),
          ),
          GoRoute(
            path: ':id/edit',
            pageBuilder: (_, state) => fadeScalePage(
              key: state.pageKey,
              child: HomestayFormScreen(homestayId: state.pathParameters['id']),
            ),
          ),
        ],
      ),

      // ── Admin – Users ──────────────────────────────────────────────────────
      GoRoute(
        path: '/admin/users',
        pageBuilder: (_, state) => horizontalPage(
          key: state.pageKey,
          child: const UserListScreen(),
        ),
        routes: [
          GoRoute(
            path: 'new',
            pageBuilder: (_, state) => fadeScalePage(
              key: state.pageKey,
              child: const UserFormScreen(),
            ),
          ),
          GoRoute(
            path: ':id/edit',
            pageBuilder: (_, state) => fadeScalePage(
              key: state.pageKey,
              child: UserFormScreen(userId: state.pathParameters['id']),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Không tìm thấy trang: ${state.error}')),
    ),
  );
});
