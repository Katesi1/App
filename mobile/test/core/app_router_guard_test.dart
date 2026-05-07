import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/app_router.dart';
import 'package:mobile/data/models/user_model.dart';
import 'package:mobile/features/auth/controllers/auth_controller.dart';
import 'package:mobile/shared/providers/view_mode_provider.dart';

void main() {
  group('resolveRedirectPath', () {
    test('redirects to login when unauthenticated and path is protected', () {
      final next = resolveRedirectPath(
        authState: AuthState(isLoggedIn: false, isLoading: false),
        viewMode: ViewMode.management,
        path: '/rooms',
      );
      expect(next, '/login');
    });

    test('sale invited cannot access rooms', () {
      final saleInvited = UserModel(
        id: 'sale-1',
        name: 'Sale',
        phone: '0900000000',
        role: 2,
        saleMembershipStatus: 'invited',
      );
      final next = resolveRedirectPath(
        authState: AuthState(
          user: saleInvited,
          isLoggedIn: true,
          isLoading: false,
        ),
        viewMode: ViewMode.management,
        path: '/rooms',
      );
      expect(next, '/dashboard');
    });

    test('sale active cannot access property mutate route directly', () {
      final saleActive = UserModel(
        id: 'sale-2',
        name: 'Sale',
        phone: '0900000001',
        role: 2,
        saleMembershipStatus: 'active',
        ownerId: 'owner-1',
      );
      final next = resolveRedirectPath(
        authState: AuthState(
          user: saleActive,
          isLoggedIn: true,
          isLoading: false,
        ),
        viewMode: ViewMode.management,
        path: '/properties/new',
      );
      expect(next, '/dashboard');
    });

    test('owner can access property mutate route after passing guards', () {
      final owner = UserModel(
        id: 'owner-1',
        name: 'Owner',
        phone: '0911111111',
        role: 1,
        kycStatus: 'approved',
      );
      final next = resolveRedirectPath(
        authState: AuthState(
          user: owner,
          isLoggedIn: true,
          isLoading: false,
        ),
        viewMode: ViewMode.management,
        path: '/properties/new',
      );
      expect(next, null);
    });

    test('non-admin cannot access admin user form route', () {
      final owner = UserModel(
        id: 'owner-1',
        name: 'Owner',
        phone: '0911111111',
        role: 1,
      );
      final next = resolveRedirectPath(
        authState: AuthState(
          user: owner,
          isLoggedIn: true,
          isLoading: false,
        ),
        viewMode: ViewMode.management,
        path: '/admin/users/new',
      );
      expect(next, '/admin');
    });

    test('non-admin cannot access admin kyc route', () {
      final owner = UserModel(
        id: 'owner-2',
        name: 'Owner',
        phone: '0922222222',
        role: 1,
      );
      final next = resolveRedirectPath(
        authState: AuthState(
          user: owner,
          isLoggedIn: true,
          isLoading: false,
        ),
        viewMode: ViewMode.management,
        path: '/admin/kyc',
      );
      expect(next, '/admin');
    });

    test('non-admin cannot access moderation audit route', () {
      final owner = UserModel(
        id: 'owner-3',
        name: 'Owner',
        phone: '0933333333',
        role: 1,
      );
      final next = resolveRedirectPath(
        authState: AuthState(
          user: owner,
          isLoggedIn: true,
          isLoading: false,
        ),
        viewMode: ViewMode.management,
        path: '/admin/moderation-audit',
      );
      expect(next, '/admin');
    });

    test('non-admin cannot access abuse reports route', () {
      final sale = UserModel(
        id: 'sale-3',
        name: 'Sale',
        phone: '0944444444',
        role: 2,
        saleMembershipStatus: 'active',
        ownerId: 'owner-1',
      );
      final next = resolveRedirectPath(
        authState: AuthState(
          user: sale,
          isLoggedIn: true,
          isLoading: false,
        ),
        viewMode: ViewMode.management,
        path: '/admin/abuse-reports',
      );
      expect(next, '/dashboard');
    });

    test('owner needsKyc is redirected from property mutate to verify flow', () {
      final ownerNeedsKyc = UserModel(
        id: 'owner-4',
        name: 'Owner',
        phone: '0955555555',
        role: 1,
        kycStatus: 'pending',
      );
      final next = resolveRedirectPath(
        authState: AuthState(
          user: ownerNeedsKyc,
          isLoggedIn: true,
          isLoading: false,
        ),
        viewMode: ViewMode.management,
        path: '/properties/new',
      );
      expect(next, '/verify/cccd-front');
    });

    test('owner needsKyc can still access properties list page', () {
      final ownerNeedsKyc = UserModel(
        id: 'owner-5',
        name: 'Owner',
        phone: '0966666666',
        role: 1,
        kycStatus: 'pending',
      );
      final next = resolveRedirectPath(
        authState: AuthState(
          user: ownerNeedsKyc,
          isLoggedIn: true,
          isLoading: false,
        ),
        viewMode: ViewMode.management,
        path: '/properties',
      );
      expect(next, null);
    });

    test('owner in customer mode is redirected away from management route', () {
      final owner = UserModel(
        id: 'owner-6',
        name: 'Owner',
        phone: '0977777777',
        role: 1,
        kycStatus: 'approved',
      );
      final next = resolveRedirectPath(
        authState: AuthState(
          user: owner,
          isLoggedIn: true,
          isLoading: false,
        ),
        viewMode: ViewMode.customer,
        path: '/dashboard',
      );
      expect(next, '/home');
    });

    test('owner in management mode is redirected away from customer route', () {
      final owner = UserModel(
        id: 'owner-7',
        name: 'Owner',
        phone: '0988888888',
        role: 1,
      );
      final next = resolveRedirectPath(
        authState: AuthState(
          user: owner,
          isLoggedIn: true,
          isLoading: false,
        ),
        viewMode: ViewMode.management,
        path: '/home',
      );
      expect(next, '/dashboard');
    });

    test('sale in customer mode is redirected away from management route', () {
      final sale = UserModel(
        id: 'sale-4',
        name: 'Sale',
        phone: '0999999999',
        role: 2,
        saleMembershipStatus: 'active',
        ownerId: 'owner-1',
      );
      final next = resolveRedirectPath(
        authState: AuthState(
          user: sale,
          isLoggedIn: true,
          isLoading: false,
        ),
        viewMode: ViewMode.customer,
        path: '/rooms',
      );
      expect(next, '/home');
    });

    test('sale in management mode is redirected away from customer route', () {
      final sale = UserModel(
        id: 'sale-5',
        name: 'Sale',
        phone: '0901111222',
        role: 2,
        saleMembershipStatus: 'active',
        ownerId: 'owner-1',
      );
      final next = resolveRedirectPath(
        authState: AuthState(
          user: sale,
          isLoggedIn: true,
          isLoading: false,
        ),
        viewMode: ViewMode.management,
        path: '/search',
      );
      expect(next, '/dashboard');
    });

    test('customer always stays in customer mode routes', () {
      final customer = UserModel(
        id: 'customer-1',
        name: 'Customer',
        phone: '0901231231',
        role: 3,
      );
      final next = resolveRedirectPath(
        authState: AuthState(
          user: customer,
          isLoggedIn: true,
          isLoading: false,
        ),
        viewMode: ViewMode.management,
        path: '/dashboard',
      );
      expect(next, '/home');
    });
  });
}
