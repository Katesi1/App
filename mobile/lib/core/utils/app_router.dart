import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/views/admin_screen.dart';
import '../../features/properties/views/property_management_screen.dart';
import '../../features/admin/views/user_form_screen.dart';
import '../../features/admin/views/user_list_screen.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/views/forgot_password_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/auth/views/splash_screen.dart';
import '../../features/bookings/views/booking_calendar_screen.dart';
import '../../features/bookings/views/owner_calendar_screen.dart';
import '../../features/customer/views/customer_home_screen.dart';
import '../../features/customer/views/search_room_screen.dart';
import '../../features/customer/views/my_bookings_screen.dart';
import '../../features/customer/views/account_screen.dart';
import '../../features/bookings/views/booking_list_screen.dart';
import '../../features/bookings/views/hold_room_screen.dart';
import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/properties/views/property_amenities_screen.dart';
import '../../features/properties/views/property_cancellation_screen.dart';
import '../../features/notifications/views/notification_screen.dart';
import '../../features/properties/views/property_manage_screen.dart';
import '../../features/properties/views/property_add_screen.dart';
import '../../features/properties/views/property_images_screen.dart';
import '../../features/properties/views/property_info_screen.dart';
import '../../features/properties/views/property_location_screen.dart';
import '../../features/properties/views/property_pricing_screen.dart';
import '../../features/properties/views/property_rules_screen.dart';
import '../../features/properties/views/property_services_screen.dart';
import '../../features/profile/views/change_password_screen.dart';
import '../../features/profile/views/help_screen.dart';
import '../../features/profile/views/personal_info_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/rooms/views/room_detail_screen.dart';
import '../../features/rooms/views/room_list_screen.dart';
import '../../features/reports/views/report_screen.dart';
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
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isLoggedIn;
      final isLoading = authState.isLoading;
      final path = state.matchedLocation;

      // Đang check token → giữ nguyên trang hiện tại
      if (isLoading) return null;

      // Các trang public (không cần login)
      const publicPaths = ['/splash', '/login', '/register', '/forgot-password'];
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
        // /profile accessible cho cả 2 mode → không nằm trong list nào
        const customerPaths = [
          '/home', '/search', '/my-bookings', '/account',
        ];
        const managementPaths = [
          '/dashboard', '/rooms', '/calendar',
          '/properties', '/admin', '/bookings', '/reports',
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
          path: '/splash', builder: (_, __) => const SplashScreen()),
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

      // ── Notifications ────────────────────────────────────────────────
      GoRoute(
        path: '/notifications',
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: const NotificationScreen(),
        ),
      ),

      // ── Profile ──────────────────────────────────────────────────────
      GoRoute(
        path: '/profile',
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: const ProfileScreen(),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            pageBuilder: (_, state) => slideUpPage(
              key: state.pageKey,
              child: const PersonalInfoScreen(),
            ),
          ),
          GoRoute(
            path: 'change-password',
            pageBuilder: (_, state) => slideUpPage(
              key: state.pageKey,
              child: const ChangePasswordScreen(),
            ),
          ),
          GoRoute(
            path: 'help',
            pageBuilder: (_, state) => slideUpPage(
              key: state.pageKey,
              child: const HelpScreen(),
            ),
          ),
        ],
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
                path: 'hold',
                pageBuilder: (_, state) => fadeScalePage(
                  key: state.pageKey,
                  child: HoldRoomScreen(
                      propertyId: state.pathParameters['id']!),
                ),
              ),
            ],
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

      // ── Reports ────────────────────────────────────────────────────
      GoRoute(
        path: '/reports',
        pageBuilder: (_, state) => horizontalPage(
          key: state.pageKey,
          child: const ReportScreen(),
        ),
      ),

      // ── Properties (quản lý phòng) ─────────────────────────────────
      GoRoute(
        path: '/properties',
        pageBuilder: (_, state) => horizontalPage(
          key: state.pageKey,
          child: const PropertyManagementScreen(),
        ),
        routes: [
          GoRoute(
            path: 'new',
            pageBuilder: (_, state) => fadeScalePage(
              key: state.pageKey,
              child: const PropertyAddScreen(),
            ),
          ),
          GoRoute(
            path: ':id',
            pageBuilder: (_, state) => slideUpPage(
              key: state.pageKey,
              child: PropertyManageScreen(
                  homestayId: state.pathParameters['id']!),
            ),
            routes: [
              GoRoute(
                path: 'images',
                pageBuilder: (_, state) => slideUpPage(
                  key: state.pageKey,
                  child: PropertyImagesScreen(
                      homestayId: state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'info',
                pageBuilder: (_, state) => slideUpPage(
                  key: state.pageKey,
                  child: PropertyInfoScreen(
                      homestayId: state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'amenities',
                pageBuilder: (_, state) => slideUpPage(
                  key: state.pageKey,
                  child: PropertyAmenitiesScreen(
                      homestayId: state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'pricing',
                pageBuilder: (_, state) => slideUpPage(
                  key: state.pageKey,
                  child: PropertyPricingScreen(
                      homestayId: state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'services',
                pageBuilder: (_, state) => slideUpPage(
                  key: state.pageKey,
                  child: PropertyServicesScreen(
                      homestayId: state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'rules',
                pageBuilder: (_, state) => slideUpPage(
                  key: state.pageKey,
                  child: PropertyRulesScreen(
                      homestayId: state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'location',
                pageBuilder: (_, state) => slideUpPage(
                  key: state.pageKey,
                  child: PropertyLocationScreen(
                      homestayId: state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'cancellation',
                pageBuilder: (_, state) => slideUpPage(
                  key: state.pageKey,
                  child: PropertyCancellationScreen(
                      homestayId: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
        ],
      ),

      // ── Admin Hub ───────────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        pageBuilder: (_, state) => horizontalPage(
          key: state.pageKey,
          child: const AdminScreen(),
        ),
      ),

      // ── Admin – Rooms Management ─────────────────────────────────
      GoRoute(
        path: '/admin/rooms',
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: const PropertyManagementScreen(),
        ),
      ),

      // ── Admin – Owner Calendar ───────────────────────────────────
      GoRoute(
        path: '/admin/owner-calendar',
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: const OwnerCalendarScreen(),
        ),
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
