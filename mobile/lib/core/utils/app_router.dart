import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/views/admin_screen.dart';
import '../../features/admin/views/admin_trial_screen.dart';
import '../../features/admin/views/abuse_reports_screen.dart';
import '../../features/admin/views/kyc_approval_detail_screen.dart';
import '../../features/admin/views/kyc_approval_list_screen.dart';
import '../../features/admin/views/moderation_audit_screen.dart';
import '../../features/admin/views/role_permission_screen.dart';
import '../../features/properties/views/property_management_screen.dart';
import '../../features/admin/views/user_form_screen.dart';
import '../../features/admin/views/user_list_screen.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/views/forgot_password_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/auth/views/role_picker_screen.dart';
import '../../features/auth/views/splash_screen.dart';
import '../../features/staff/views/invite_accept_screen.dart';
import '../../features/staff/views/staff_management_screen.dart';
import '../../features/bookings/views/booking_calendar_screen.dart';
import '../../features/bookings/views/owner_calendar_screen.dart';
import '../../features/customer/views/customer_home_screen.dart';
import '../../features/customer/views/search_room_screen.dart';
import '../../features/customer/views/my_bookings_screen.dart';
import '../../features/customer/views/account_screen.dart';
import '../../features/bookings/views/booking_list_screen.dart';
import '../../features/bookings/views/booking_detail_screen.dart';
import '../../features/bookings/views/guest_flow_list_screen.dart';
import '../../features/bookings/views/hold_room_screen.dart';
import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/properties/views/property_amenities_screen.dart';
import '../../features/properties/views/property_cancellation_screen.dart';
import '../../features/notifications/views/notification_detail_screen.dart';
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
import '../../features/profile/views/consent_screen.dart';
import '../../features/profile/views/data_request_screen.dart';
import '../../features/profile/views/delete_account_screen.dart';
import '../../features/profile/views/feedback_report_screen.dart';
import '../../features/profile/views/force_update_screen.dart';
import '../../features/profile/views/help_screen.dart';
import '../../features/profile/views/my_tickets_screen.dart';
import '../../features/profile/views/notification_preferences_screen.dart';
import '../../features/profile/views/personal_info_screen.dart';
import '../../features/profile/views/privacy_policy_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/profile/views/terms_of_service_screen.dart';
import '../../features/rooms/views/room_detail_screen.dart';
import '../../features/rooms/views/room_list_screen.dart';
import '../../features/reports/views/report_screen.dart';
import '../../features/reviews/views/property_reviews_screen.dart';
import '../../features/reviews/views/write_review_screen.dart';
import '../../features/verify/data/models/verify_enums.dart';
import '../../features/verify/views/cccd_capture_screen.dart';
import '../../features/verify/views/payment_history_screen.dart';
import '../../features/verify/views/payment_screen.dart';
import '../../features/verify/views/pending_approval_screen.dart';
import '../../features/verify/views/rejected_screen.dart';
import '../../features/verify/views/select_plan_screen.dart';
import '../../features/verify/views/subscription_detail_screen.dart';
import '../../features/verify/views/selfie_capture_screen.dart';
import '../../features/verify/views/trial_active_screen.dart';
import '../../shared/providers/view_mode_provider.dart';
import 'app_transitions.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
    ref.listen<ViewMode>(viewModeProvider, (_, __) => notifyListeners());
  }
}

String? resolveRedirectPath({
  required AuthState authState,
  required ViewMode viewMode,
  required String path,
}) {
  final isLoggedIn = authState.isLoggedIn;
  final isLoading = authState.isLoading;

  // Đang check token -> giữ nguyên trang hiện tại
  if (isLoading) return null;

  // Các trang public (không cần login)
  const publicPaths = [
    '/splash',
    '/login',
    '/register',
    '/forgot-password',
    '/auth/role-picker',
    '/staff/accept',
  ];
  final isPublic = publicPaths.contains(path);

  // Chưa login -> redirect về login
  if (!isLoggedIn && !isPublic) return '/login';

  if (!isLoggedIn) return null;

  final user = authState.user;
  final bool isCustomerMode;
  if (user != null && user.isCustomer) {
    isCustomerMode = true;
  } else if (user != null && user.isManagement) {
    isCustomerMode = viewMode == ViewMode.customer;
  } else {
    isCustomerMode = false;
  }

  // Redirect khỏi trang public
  if (isPublic) {
    return isCustomerMode ? '/home' : '/dashboard';
  }

  // Route guard
  // /profile accessible cho cả 2 mode -> không nằm trong list nào
  const customerPaths = [
    '/home',
    '/search',
    '/my-bookings',
    '/account',
  ];
  const managementPaths = [
    '/dashboard',
    '/rooms',
    '/calendar',
    '/properties',
    '/admin',
    '/bookings',
    '/reports',
    '/staff',
  ];

  // Đang ở mode khách -> chặn route quản lý
  if (isCustomerMode) {
    final isManagementRoute = managementPaths.any(
      (p) => path == p || path.startsWith('$p/'),
    );
    if (isManagementRoute) return '/home';
  }

  // Đang ở mode quản lý -> chặn route khách
  if (!isCustomerMode && user != null && user.isManagement) {
    final isCustomerRoute = customerPaths.contains(path);
    if (isCustomerRoute) return '/dashboard';
  }

  // Chỉ ADMIN và OWNER vào route admin
  if (user != null && !(user.isAdmin || user.isOwner)) {
    if (path.startsWith('/admin')) return '/dashboard';
  }

  // Chỉ OWNER quản lý nhân viên (SALE/CUSTOMER/ADMIN không vào /staff/manage)
  if (user != null && !user.isOwner) {
    if (path == '/staff/manage' || path.startsWith('/staff/manage/')) {
      return '/dashboard';
    }
  }

  // SALE chỉ được vào luồng quản lý khi membership active.
  // invited/suspended/unassigned: chỉ cho ở dashboard + profile/help.
  if (user != null && user.isSale && !user.isSaleMembershipActive) {
    const allowedWhenInactiveSale = [
      '/dashboard',
      '/profile',
      '/profile/help',
      '/notifications',
    ];
    final isAllowed =
        allowedWhenInactiveSale.any((p) => path == p || path.startsWith('$p/'));
    if (!isAllowed) return '/dashboard';
  }

  // SALE không tạo property mới; edit sub-paths (images/info/...) backend 403.
  if (user != null && user.isSale) {
    if (path == '/properties/new') return '/dashboard';
  }

  // Các route quản trị người dùng/moderation là admin-only.
  if (user != null && !user.isAdmin) {
    final isUserFormRoute = path == '/admin/users/new' ||
        RegExp(r'^/admin/users/[^/]+/edit$').hasMatch(path);
    final isTrialRoute = RegExp(r'^/admin/users/[^/]+/trial$').hasMatch(path);
    const adminOnlyPrefixes = [
      '/admin/abuse-reports',
      '/admin/moderation-audit',
      '/admin/kyc',
      '/admin/role-permissions',
    ];
    final isAdminOnly = isUserFormRoute ||
        isTrialRoute ||
        adminOnlyPrefixes.any((p) => path == p || path.startsWith(p));
    if (isAdminOnly) return '/admin';
  }

  // OWNER chưa hoàn thành KYC -> chặn mọi mutate page dưới /properties.
  // Cho phép /properties (list) để user xem state hiện tại + banner CTA.
  // Backend sẽ trả 403 nếu lọt qua, đây chỉ là UX guard.
  if (user != null && user.needsKyc) {
    if (path != '/properties' && path.startsWith('/properties/')) {
      return '/verify/cccd-front';
    }
  }

  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      return resolveRedirectPath(
        authState: ref.read(authProvider),
        viewMode: ref.read(viewModeProvider),
        path: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/auth/role-picker',
        builder: (_, state) {
          final args = state.extra as RolePickerArgs?;
          if (args == null) {
            // Defensive: nếu navigate sai (vd cold deeplink) → quay về login.
            return const LoginScreen();
          }
          return RolePickerScreen(args: args);
        },
      ),

      // Staff invite — public, dùng cho deep link email + entry "Tôi có mã mời"
      GoRoute(
        path: '/staff/accept',
        builder: (_, state) {
          final token = state.uri.queryParameters['token'];
          return InviteAcceptScreen(initialToken: token);
        },
      ),

      // OWNER quản lý nhân viên (mời + danh sách)
      GoRoute(
        path: '/staff/manage',
        builder: (_, __) => const StaffManagementScreen(),
      ),

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
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (_, state) => slideUpPage(
              key: state.pageKey,
              child: NotificationDetailScreen(
                id: state.pathParameters['id']!,
              ),
            ),
          ),
        ],
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
          GoRoute(
            path: 'privacy',
            pageBuilder: (_, state) => slideUpPage(
              key: state.pageKey,
              child: const PrivacyPolicyScreen(),
            ),
          ),
          GoRoute(
            path: 'terms',
            pageBuilder: (_, state) => slideUpPage(
              key: state.pageKey,
              child: const TermsOfServiceScreen(),
            ),
          ),
          GoRoute(
            path: 'consent',
            pageBuilder: (_, state) => slideUpPage(
              key: state.pageKey,
              child: const ConsentScreen(),
            ),
          ),
          GoRoute(
            path: 'notifications',
            pageBuilder: (_, state) => slideUpPage(
              key: state.pageKey,
              child: const NotificationPreferencesScreen(),
            ),
          ),
          GoRoute(
            path: 'feedback',
            pageBuilder: (_, state) => slideUpPage(
              key: state.pageKey,
              child: const FeedbackReportScreen(),
            ),
          ),
          GoRoute(
            path: 'tickets',
            pageBuilder: (_, state) => slideUpPage(
              key: state.pageKey,
              child: const MyTicketsScreen(),
            ),
          ),
          GoRoute(
            path: 'delete-account',
            pageBuilder: (_, state) => slideUpPage(
              key: state.pageKey,
              child: const DeleteAccountScreen(),
            ),
          ),
          GoRoute(
            path: 'data-request',
            pageBuilder: (_, state) => slideUpPage(
              key: state.pageKey,
              child: const DataRequestScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/update-required',
        builder: (_, __) => const ForceUpdateScreen(),
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
              child: RoomDetailScreen(roomId: state.pathParameters['id']!),
            ),
            routes: [
              GoRoute(
                path: 'hold',
                pageBuilder: (_, state) => fadeScalePage(
                  key: state.pageKey,
                  child:
                      HoldRoomScreen(propertyId: state.pathParameters['id']!),
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
        routes: [
          GoRoute(
            path: 'check-in',
            pageBuilder: (_, state) => horizontalPage(
              key: state.pageKey,
              child: const CheckInListScreen(),
            ),
          ),
          GoRoute(
            path: 'check-out',
            pageBuilder: (_, state) => horizontalPage(
              key: state.pageKey,
              child: const CheckOutListScreen(),
            ),
          ),
          GoRoute(
            path: ':id',
            pageBuilder: (_, state) => horizontalPage(
              key: state.pageKey,
              child: BookingDetailScreen(
                id: state.pathParameters['id']!,
              ),
            ),
          ),
        ],
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
              child:
                  PropertyManageScreen(homestayId: state.pathParameters['id']!),
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

      // ── Reviews ─────────────────────────────────────────────────────
      // `/reviews/:id` = public list. `/reviews/:id/write?bookingId=xxx` =
      // customer viết review sau khi booking completed. Đặt ngoài
      // `/properties/...` để không bị guard mode/role block (xem
      // `resolveRedirectPath` — paths không trong customer/management
      // list sẽ pass through cho cả 2 mode).
      GoRoute(
        path: '/reviews/:id',
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: PropertyReviewsScreen(
            propertyId: state.pathParameters['id']!,
            propertyName: state.uri.queryParameters['name'],
          ),
        ),
        routes: [
          GoRoute(
            path: 'write',
            pageBuilder: (_, state) {
              final bookingId = state.uri.queryParameters['bookingId'];
              if (bookingId == null || bookingId.isEmpty) {
                return slideUpPage(
                  key: state.pageKey,
                  child: const _MissingBookingScreen(),
                );
              }
              return slideUpPage(
                key: state.pageKey,
                child: WriteReviewScreen(
                  propertyId: state.pathParameters['id']!,
                  bookingId: bookingId,
                  propertyName: state.uri.queryParameters['name'],
                ),
              );
            },
          ),
        ],
      ),

      // ── Verify + Subscription Flow ──────────────────────────────────
      // 8 screens — paywall (modal, không nằm trong router) + 7 screens dưới đây.
      // Trigger paywall: gọi `showPaywallModal(context)` từ bất kỳ feature
      // bị lock nào (property management, room management...). Sau khi user
      // tap "Bắt đầu ngay" → push `/verify/cccd-front`.
      GoRoute(
        path: '/verify/cccd-front',
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: CCCDCaptureScreen(
            side: CCCDSide.front,
            isResubmit: state.uri.queryParameters['resubmit'] == '1',
          ),
        ),
      ),
      GoRoute(
        path: '/verify/cccd-back',
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: CCCDCaptureScreen(
            side: CCCDSide.back,
            isResubmit: state.uri.queryParameters['resubmit'] == '1',
          ),
        ),
      ),
      GoRoute(
        path: '/verify/selfie',
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: SelfieCaptureScreen(
            isResubmit: state.uri.queryParameters['resubmit'] == '1',
          ),
        ),
      ),
      GoRoute(
        path: '/verify/select-plan',
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: SelectPlanScreen(
            isUpgrade: state.uri.queryParameters['mode'] == 'upgrade',
          ),
        ),
      ),
      GoRoute(
        path: '/verify/payment',
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: const PaymentScreen(),
        ),
      ),
      GoRoute(
        path: '/verify/pending',
        pageBuilder: (_, state) => fadeScalePage(
          key: state.pageKey,
          child: const PendingApprovalScreen(),
        ),
      ),
      GoRoute(
        path: '/verify/approved',
        pageBuilder: (_, state) => fadeScalePage(
          key: state.pageKey,
          child: const TrialActiveScreen(),
        ),
      ),
      GoRoute(
        path: '/verify/subscription-detail',
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: const SubscriptionDetailScreen(),
        ),
      ),
      GoRoute(
        path: '/verify/payment-history',
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: const PaymentHistoryScreen(),
        ),
      ),
      GoRoute(
        path: '/verify/rejected',
        pageBuilder: (_, state) => fadeScalePage(
          key: state.pageKey,
          child: const RejectedScreen(),
        ),
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
      GoRoute(
        path: '/admin/abuse-reports',
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: const AbuseReportsScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/moderation-audit',
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: const ModerationAuditScreen(),
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

      // ── Admin – KYC approval queue ────────────────────────────────
      GoRoute(
        path: '/admin/kyc',
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: const KYCApprovalListScreen(),
        ),
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (_, state) => slideUpPage(
              key: state.pageKey,
              child: KYCApprovalDetailScreen(
                submissionId: state.pathParameters['id']!,
              ),
            ),
          ),
        ],
      ),

      // ── Admin – Role Permissions ──────────────────────────────────
      GoRoute(
        path: '/admin/role-permissions',
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: const RolePermissionScreen(),
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
              child: UserFormScreen(userId: state.pathParameters['id']),
            ),
          ),
          GoRoute(
            path: ':id/trial',
            pageBuilder: (_, state) => slideUpPage(
              key: state.pageKey,
              child: AdminTrialScreen(
                userId: state.pathParameters['id']!,
                userName: state.uri.queryParameters['name'],
              ),
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

/// Fallback khi mở `/reviews/:id/write` mà thiếu `bookingId` query param —
/// route hợp lệ nhưng thiếu data, không nên crash.
class _MissingBookingScreen extends StatelessWidget {
  const _MissingBookingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Viết đánh giá')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Thiếu thông tin booking. Mở từ "Booking của tôi" → booking đã hoàn tất.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
