import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/views/user_form_screen.dart';
import '../../features/admin/views/user_list_screen.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/views/forgot_password_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/bookings/views/booking_calendar_screen.dart';
import '../../features/customer/views/customer_home_screen.dart';
import '../../features/customer/views/search_room_screen.dart';
import '../../features/customer/views/my_bookings_screen.dart';
import '../../features/customer/views/account_screen.dart';
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
import '../../shared/providers/view_mode_provider.dart';
import 'app_transitions.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
    ref.listen<ViewMode>(viewModeProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isLoggedIn;
      final isLoading = authState.isLoading;
      final path = state.matchedLocation;

      // Đang check token → giữ nguyên trang hiện tại
      if (isLoading) return null;

      // Các trang public (không cần login)
      const publicPaths = ['/login', '/register', '/forgot-password'];
      final isPublic = publicPaths.contains(path);

      // Chưa login → redirect về login
      if (!isLoggedIn && !isPublic) return '/login';

      // Đã login → tính isCustomerMode trực tiếp từ authState
      // (KHÔNG dùng ref.read(isCustomerModeProvider) vì provider chain
      //  có thể chưa propagate kịp khi redirect chạy ngay sau login)
      if (isLoggedIn) {
        final user = authState.user;
        final bool isCustomerMode;
        if (user != null && user.isCustomer) {
          isCustomerMode = true;
        } else if (user != null && user.isManagement) {
          isCustomerMode =
              ref.read(viewModeProvider) == ViewMode.customer;
        } else {
          isCustomerMode = false;
        }

        // Redirect khỏi trang public
        if (isPublic) {
          return isCustomerMode ? '/home' : '/dashboard';
        }

        // Route guard
        const customerPaths = [
          '/home', '/search', '/my-bookings', '/account',
        ];
        const managementPaths = [
          '/dashboard', '/rooms', '/calendar',
          '/homestays', '/admin', '/bookings',
        ];

        // Đang ở mode khách → chặn route quản lý
        if (isCustomerMode) {
          final isManagementRoute = managementPaths.any(
            (p) => path == p || path.startsWith('$p/'),
          );
          if (isManagementRoute) return '/home';
        }

        // Đang ở mode quản lý → chặn route khách
        if (!isCustomerMode && user != null && user.isManagement) {
          final isCustomerRoute = customerPaths.contains(path);
          if (isCustomerRoute) return '/dashboard';
        }

        // Staff/Customer không vào route admin
        if (user != null && !user.isAdmin) {
          if (path.startsWith('/admin')) return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
          path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/register',
          builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),

      // ── Customer routes ────────────────────────────────────────────
      GoRoute(
        path: '/home',
        pageBuilder: (_, state) => horizontalPage(
          key: state.pageKey,
          child: const CustomerHomeScreen(),
        ),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (_, state) => horizontalPage(
          key: state.pageKey,
          child: const SearchRoomScreen(),
        ),
      ),
      GoRoute(
        path: '/my-bookings',
        pageBuilder: (_, state) => horizontalPage(
          key: state.pageKey,
          child: const MyBookingsScreen(),
        ),
      ),
      GoRoute(
        path: '/account',
        pageBuilder: (_, state) => horizontalPage(
          key: state.pageKey,
          child: const AccountScreen(),
        ),
      ),

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

      // ── Calendar (bottom nav "Lịch") ─────────────────────────────
      GoRoute(
        path: '/calendar',
        pageBuilder: (_, state) => horizontalPage(
          key: state.pageKey,
          child: const BookingCalendarScreen(),
        ),
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
