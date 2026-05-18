import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    group('fromJson', () {
      test('parses full JSON correctly', () {
        final json = {
          'id': 'user-1',
          'name': 'Nguyễn Văn A',
          'phone': '0912345678',
          'email': 'a@test.com',
          'role': 0, // ADMIN
          'isActive': true,
        };

        final user = UserModel.fromJson(json);

        expect(user.id, 'user-1');
        expect(user.name, 'Nguyễn Văn A');
        expect(user.phone, '0912345678');
        expect(user.email, 'a@test.com');
        expect(user.role, 0);
        expect(user.isActive, true);
      });

      test('uses defaults for missing fields', () {
        final user = UserModel.fromJson({});

        expect(user.id, '');
        expect(user.name, '');
        expect(user.phone, '');
        expect(user.email, isNull);
        expect(user.role, 3); // CUSTOMER
        expect(user.isActive, true);
      });

      test('handles null values gracefully', () {
        final json = {
          'id': null,
          'name': null,
          'phone': null,
          'email': null,
          'role': null,
          'isActive': null,
        };

        final user = UserModel.fromJson(json);

        expect(user.id, '');
        expect(user.name, '');
        expect(user.role, 3); // CUSTOMER
        expect(user.isActive, true);
      });
    });

    group('toJson', () {
      test('serializes correctly', () {
        final user = UserModel(
          id: 'user-1',
          name: 'Test',
          phone: '0912345678',
          email: 'test@test.com',
          role: 2, // SALE
        );

        final json = user.toJson();

        expect(json['id'], 'user-1');
        expect(json['name'], 'Test');
        expect(json['phone'], '0912345678');
        expect(json['email'], 'test@test.com');
        expect(json['role'], 2);
        expect(json['isActive'], true);
      });
    });

    group('JSON round-trip', () {
      test('fromJsonString → toJsonString preserves data', () {
        final original = UserModel(
          id: 'u-1',
          name: 'Round Trip',
          phone: '0999888777',
          role: 2, // SALE
        );

        final jsonStr = original.toJsonString();
        final restored = UserModel.fromJsonString(jsonStr);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.phone, original.phone);
        expect(restored.role, original.role);
      });

      test('toJsonString produces valid JSON', () {
        final user = UserModel(
          id: 'u-1',
          name: 'Test',
          phone: '0912345678',
          role: 0, // ADMIN
        );

        final jsonStr = user.toJsonString();
        expect(() => jsonDecode(jsonStr), returnsNormally);
      });
    });

    group('role helpers', () {
      test('isAdmin returns true for role=0', () {
        final user = _makeUser(role: 0);
        expect(user.isAdmin, true);
        expect(user.isOwner, false);
        expect(user.isSale, false);
      });

      test('isOwner returns true for role=1', () {
        final user = _makeUser(role: 1);
        expect(user.isAdmin, false);
        expect(user.isOwner, true);
        expect(user.isSale, false);
      });

      test('isSale returns true for role=2', () {
        final user = _makeUser(role: 2);
        expect(user.isAdmin, false);
        expect(user.isOwner, false);
        expect(user.isSale, true);
      });

      test('isManagement true for ADMIN/OWNER/SALE', () {
        expect(_makeUser(role: 0).isManagement, true);
        expect(_makeUser(role: 1).isManagement, true);
        expect(_makeUser(role: 2).isManagement, true);
      });

      test('canEdit true for ADMIN, OWNER, SALE', () {
        expect(_makeUser(role: 0).canEdit, true);
        expect(_makeUser(role: 1).canEdit, true);
        expect(_makeUser(role: 2).canEdit, true);
      });
    });

    group('sale membership helpers', () {
      test('falls back to unassigned when sale has no owner and no status', () {
        final user = _makeUser(role: 2);
        expect(user.saleMembershipState, 'unassigned');
        expect(user.isSaleMembershipUnassigned, true);
        expect(user.isSaleMembershipActive, false);
      });

      test('falls back to active when sale has owner and no status', () {
        final user = UserModel(
          id: 'sale-1',
          name: 'Sale',
          phone: '0900000000',
          role: 2,
          ownerId: 'owner-1',
        );
        expect(user.saleMembershipState, 'active');
        expect(user.isSaleMembershipActive, true);
      });

      test('uses explicit saleMembershipStatus from backend', () {
        final user = UserModel.fromJson({
          'id': 'sale-1',
          'role': 2,
          'saleMembershipStatus': 'suspended',
        });
        expect(user.saleMembershipState, 'suspended');
        expect(user.isSaleMembershipSuspended, true);
        expect(user.isSaleMembershipActive, false);
      });

      test('canMutateManagementData requires active membership for sale', () {
        final saleInvited = UserModel(
          id: 'sale-1',
          name: 'Sale',
          phone: '0900000000',
          role: 2,
          saleMembershipStatus: 'invited',
        );
        final saleActive = UserModel(
          id: 'sale-2',
          name: 'Sale',
          phone: '0900000001',
          role: 2,
          saleMembershipStatus: 'active',
        );
        final owner = _makeUser(role: 1);
        final admin = _makeUser(role: 0);

        expect(saleInvited.canMutateManagementData, false);
        expect(saleActive.canMutateManagementData, true);
        expect(owner.canMutateManagementData, true);
        expect(admin.canMutateManagementData, true);
      });
    });
  });
}

UserModel _makeUser({required int role}) {
  return UserModel(
    id: 'test-id',
    name: 'Test User',
    phone: '0912345678',
    role: role,
  );
}
