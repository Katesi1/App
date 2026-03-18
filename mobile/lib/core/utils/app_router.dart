import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/views/user_form_screen.dart';
import '../../features/admin/views/user_list_screen.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/views/forgot_password_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/bookings/views/booking_list_screen.dart';
import '../../features/bookings/views/hold_room_screen.dart';
import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/homestays/views/homestay_form_screen.dart';
import '../../features/homestays/views/homestay_list_screen.dart';
import '../../features/rooms/views/room_calendar_screen.dart';
import '../../features/rooms/views/room_detail_screen.dart';
import '../../features/rooms/views/room_form_screen.dart';
import '../../features/rooms/views/room_images_screen.dart';
import '../../features/rooms/views/room_list_screen.dart';
import '../../features/rooms/views/room_price_screen.dart';
import 'app_transitions.dart';

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isLoggedIn;
      final isLoading = authState.isLoading;
      final isLogin = state.matchedLocation == '/login';

      // Đang check token → giữ nguyên trang hiện tại
      if (isLoading) return null;
      final isForgotPassword =
          state.matchedLocation == '/forgot-password';
      if (!isLoggedIn && !isLogin && !isForgotPassword) {
        return '/login';
      }
      if (isLoggedIn && (isLogin || isForgotPassword)) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
          path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),

      // ── Dashboard (home) ───────────────────────────────────────────
      GoRoute(
        path: '/dashboard',
        pageBuilder: (_, state) => horizontalPage(
          key: state.pageKey,
          child: const DashboardScreen(),
        ),
      ),

      // ── Rooms ──────────────────────────────────────────────────────
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
              child: RoomDetailScreen(
                  roomId: state.pathParameters['id']!),
            ),
            routes: [
              GoRoute(
                path: 'calendar',
                pageBuilder: (_, state) => slideUpPage(
                  key: state.pageKey,
                  child: RoomCalendarScreen(
                      roomId: state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'hold',
                pageBuilder: (_, state) => fadeScalePage(
                  key: state.pageKey,
                  child: HoldRoomScreen(
                      roomId: state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'images',
                pageBuilder: (_, state) => slideUpPage(
                  key: state.pageKey,
                  child: RoomImagesScreen(
                      roomId: state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'price',
                pageBuilder: (_, state) => slideUpPage(
                  key: state.pageKey,
                  child: RoomPriceScreen(
                      roomId: state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'edit',
                pageBuilder: (_, state) => fadeScalePage(
                  key: state.pageKey,
                  child: RoomFormScreen(
                      roomId: state.pathParameters['id']),
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

      // ── Bookings ───────────────────────────────────────────────────
      GoRoute(
        path: '/bookings',
        pageBuilder: (_, state) => horizontalPage(
          key: state.pageKey,
          child: const BookingListScreen(),
        ),
      ),

      // ── Homestays ──────────────────────────────────────────────────
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
              child: HomestayFormScreen(
                  homestayId: state.pathParameters['id']),
            ),
          ),
        ],
      ),

      // ── Admin – Users ──────────────────────────────────────────────
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
              child: UserFormScreen(
                  userId: state.pathParameters['id']),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(
          child: Text('Không tìm thấy trang: ${state.error}')),
    ),
  );
});
