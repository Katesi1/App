import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/views/admin_screen.dart';
import '../../features/admin/views/abuse_reports_screen.dart';
import '../../features/admin/views/kyc_approval_detail_screen.dart';
import '../../features/admin/views/kyc_approval_list_screen.dart';
import '../../features/admin/views/moderation_audit_screen.dart';
import '../../features/admin/views/role_permission_screen.dart';
import '../../features/admin/views/staff_permission_screen.dart';
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
import '../../features/bookings/views/booking_calendar_screen.dart';
import '../../features/bookings/views/owner_calendar_screen.dart';
import '../../features/bookings/views/booking_list_screen.dart';
import '../../features/bookings/views/front_desk_screen.dart';
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
import '../../features/profile/views/ticket_detail_screen.dart';
import '../../features/profile/views/notification_preferences_screen.dart';
import '../../features/profile/views/personal_info_screen.dart';
import '../../features/profile/views/privacy_policy_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/profile/views/terms_of_service_screen.dart';
import '../../features/bookings/views/hold_room_screen.dart';
import '../../features/rooms/views/room_detail_screen.dart';
import '../../features/rooms/views/room_list_screen.dart';
import '../../features/reports/views/report_screen.dart';
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
import 'app_transitions.dart';
import '../config/app_config.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

String? resolveRedirectPath({
  required AuthState authState,
  required String path,
}) {
  final isLoggedIn = authState.isLoggedIn;
  final isLoading = authState.isLoading;

  // Stay on current screen while token check is in flight.
  if (isLoading) return null;

  const publicPaths = [
    '/splash',
    '/login',
    '/register',
    '/forgot-password',
    '/auth/role-picker',
    '/staff/accept',
  ];
  final isPublic = publicPaths.contains(path);

  // B2B app for OWNER + SALE only — login is required for every screen.
  if (!isLoggedIn) {
    return isPublic ? null : '/login';
  }

  final user = authState.user;

  // Logged-in users on a public path → bounce to dashboard.
  if (isPublic) return '/dashboard';

  // Admin-only namespace.
  if (user != null && !(user.isAdmin || user.isOwner)) {
    if (path.startsWith('/admin')) return '/dashboard';
  }

  // SALE without active membership (invited/suspended/unassigned) is locked
  // down to the dashboard + profile/help until OWNER activates them.
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

  // SALE cannot create/edit properties even if backend would also block them.
  if (user != null && user.isSale) {
    final isPropertyMutatePath = path == '/properties/new' ||
        path.startsWith('/properties/') && path != '/properties';
    if (isPropertyMutatePath) return '/dashboard';
  }

  // User/moderation admin routes are admin-only.
  if (user != null && !user.isAdmin) {
    final isUserFormRoute = path == '/admin/users/new' ||
        RegExp(r'^/admin/users/[^/]+/edit$').hasMatch(path);
    const adminOnlyPrefixes = [
      '/admin/abuse-reports',
      '/admin/moderation-audit',
      '/admin/kyc',
      '/admin/role-permissions',
    ];
    final isAdminOnly = isUserFormRoute ||
        adminOnlyPrefixes.any((p) => path == p || path.startsWith(p));
    if (isAdminOnly) return '/admin';
  }

  // iOS (Guideline 3.1.1): the paid-upgrade surface is hidden. Any deep-link /
  // stray navigation to a plan-price or payment screen is bounced to dashboard
  // so a reviewer can never reach an out-of-IAP purchase flow. KYC capture
  // screens (cccd/selfie/pending/rejected) stay reachable — identity only.
  if (AppConfig.hidePaidUpgradeUI) {
    const hiddenPaymentRoutes = {
      '/verify/select-plan',
      '/verify/payment',
      '/verify/approved', // trial-active shows plan price + renew CTA
      '/verify/subscription-detail',
      '/verify/payment-history',
    };
    if (hiddenPaymentRoutes.contains(path)) return '/dashboard';
  }

  // OWNER without completed KYC: block every mutate page under /properties.
  // Keep /properties (list) accessible so the user can see status + CTA banner.
  // Backend still returns 403 if a request slips through — this is a UX guard.
  //
  // KYC (identity) is the only gate to create rooms — there is NO payment/plan
  // requirement (the buy-plan step was removed). On iOS the KYC flow shows no
  // payment wording; on both platforms KYC-approved owners can create freely.
  if (user != null && user.needsKyc) {
    if (path != '/properties' && path.startsWith('/properties/')) {
      // Route to the screen matching the SERVER status — a pending owner must
      // land on "chờ duyệt", NOT be sent back to re-do KYC.
      return switch (user.kycStatus) {
        'pending' => '/verify/pending',
        'rejected' => '/verify/rejected',
        _ => '/verify/cccd-front',
      };
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
            // Defensive fallback for invalid navigation (e.g. cold deep link).
            return const LoginScreen();
          }
          return RolePickerScreen(args: args);
        },
      ),

      // Staff invite — public, used by email deep link + "I have an invite code" entry.
      GoRoute(
        path: '/staff/accept',
        builder: (_, state) {
          final token = state.uri.queryParameters['token'];
          return InviteAcceptScreen(initialToken: token);
        },
      ),

      // Notifications
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
            path: 'tickets/:id',
            pageBuilder: (_, state) => slideUpPage(
              key: state.pageKey,
              child: TicketDetailScreen(
                ticketId: state.pathParameters['id'] ?? '',
              ),
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

      // ── Calendar (bottom nav) ────────────────────────────────────
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

      // ── Front desk (check-in / check-out by day) ───────────────────
      GoRoute(
        path: '/front-desk',
        pageBuilder: (_, state) => horizontalPage(
          key: state.pageKey,
          child: FrontDeskScreen(
            initialTab: state.uri.queryParameters['tab'],
          ),
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

      // ── Properties (management) ────────────────────────────────────
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

      // ── Verify + Subscription Flow ──────────────────────────────────
      // 7 routed screens + the paywall modal (not part of the router).
      // Paywall trigger: call `showPaywallModal(context)` from any locked
      // feature (property management, etc.). Tapping "Get started" pushes
      // `/verify/cccd-front`.
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
          child: const SelectPlanScreen(),
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
      GoRoute(
        path: '/admin/role-permissions/:userId',
        pageBuilder: (_, state) => slideUpPage(
          key: state.pageKey,
          child: StaffPermissionScreen(
            userId: state.pathParameters['userId'] ?? '',
          ),
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
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Không tìm thấy trang: ${state.error}')),
    ),
  );
});
