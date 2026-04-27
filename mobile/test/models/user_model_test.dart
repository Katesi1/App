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
        expect(user.isCustomer, false);
      });

      test('isOwner returns true for role=1', () {
        final user = _makeUser(role: 1);
        expect(user.isAdmin, false);
        expect(user.isOwner, true);
        expect(user.isSale, false);
        expect(user.isCustomer, false);
      });

      test('isSale returns true for role=2', () {
        final user = _makeUser(role: 2);
        expect(user.isAdmin, false);
        expect(user.isOwner, false);
        expect(user.isSale, true);
        expect(user.isCustomer, false);
      });

      test('isCustomer returns true for role=3', () {
        final user = _makeUser(role: 3);
        expect(user.isAdmin, false);
        expect(user.isOwner, false);
        expect(user.isSale, false);
        expect(user.isCustomer, true);
      });

      test('isManagement true for ADMIN (0)', () {
        expect(_makeUser(role: 0).isManagement, true);
      });

      test('isManagement true for OWNER (1)', () {
        expect(_makeUser(role: 1).isManagement, true);
      });

      test('isManagement true for SALE (2)', () {
        expect(_makeUser(role: 2).isManagement, true);
      });

      test('isManagement false for CUSTOMER (3)', () {
        expect(_makeUser(role: 3).isManagement, false);
      });

      test('canEdit true for ADMIN, OWNER, SALE', () {
        expect(_makeUser(role: 0).canEdit, true);
        expect(_makeUser(role: 1).canEdit, true);
        expect(_makeUser(role: 2).canEdit, true);
      });

      test('canEdit false for CUSTOMER', () {
        expect(_makeUser(role: 3).canEdit, false);
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
