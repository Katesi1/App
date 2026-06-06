import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/app_router.dart';
import 'package:mobile/data/models/user_model.dart';
import 'package:mobile/features/auth/controllers/auth_controller.dart';

void main() {
  group('resolveRedirectPath', () {
    test('redirects to login when unauthenticated and path is protected', () {
      final next = resolveRedirectPath(
        authState: AuthState(isLoggedIn: false, isLoading: false),
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
        path: '/admin/users/new',
      );
      expect(next, '/admin');
    });

    test('customer role is redirected to login', () {
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
        path: '/dashboard',
      );
      expect(next, '/login');
    });

    test('legacy customer routes redirect to dashboard', () {
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
        path: '/search',
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
        path: '/properties',
      );
      expect(next, null);
    });
  });
}
