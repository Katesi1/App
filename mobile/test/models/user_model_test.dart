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
          'role': 'ADMIN',
          'isActive': true,
        };

        final user = UserModel.fromJson(json);

        expect(user.id, 'user-1');
        expect(user.name, 'Nguyễn Văn A');
        expect(user.phone, '0912345678');
        expect(user.email, 'a@test.com');
        expect(user.role, 'ADMIN');
        expect(user.isActive, true);
      });

      test('uses defaults for missing fields', () {
        final user = UserModel.fromJson({});

        expect(user.id, '');
        expect(user.name, '');
        expect(user.phone, '');
        expect(user.email, isNull);
        expect(user.role, 'CUSTOMER');
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
        expect(user.role, 'CUSTOMER');
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
          role: 'STAFF',
        );

        final json = user.toJson();

        expect(json['id'], 'user-1');
        expect(json['name'], 'Test');
        expect(json['phone'], '0912345678');
        expect(json['email'], 'test@test.com');
        expect(json['role'], 'STAFF');
        expect(json['isActive'], true);
      });
    });

    group('JSON round-trip', () {
      test('fromJsonString → toJsonString preserves data', () {
        final original = UserModel(
          id: 'u-1',
          name: 'Round Trip',
          phone: '0999888777',
          role: 'STAFF',
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
          role: 'ADMIN',
        );

        final jsonStr = user.toJsonString();
        expect(() => jsonDecode(jsonStr), returnsNormally);
      });
    });

    group('role helpers', () {
      test('isAdmin returns true for ADMIN', () {
        final user = _makeUser(role: 'ADMIN');
        expect(user.isAdmin, true);
        expect(user.isStaff, false);
        expect(user.isCustomer, false);
      });

      test('isStaff returns true for STAFF', () {
        final user = _makeUser(role: 'STAFF');
        expect(user.isAdmin, false);
        expect(user.isStaff, true);
        expect(user.isCustomer, false);
      });

      test('isCustomer returns true for CUSTOMER', () {
        final user = _makeUser(role: 'CUSTOMER');
        expect(user.isAdmin, false);
        expect(user.isStaff, false);
        expect(user.isCustomer, true);
      });

      test('isManagement true for ADMIN', () {
        expect(_makeUser(role: 'ADMIN').isManagement, true);
      });

      test('isManagement true for STAFF', () {
        expect(_makeUser(role: 'STAFF').isManagement, true);
      });

      test('isManagement false for CUSTOMER', () {
        expect(_makeUser(role: 'CUSTOMER').isManagement, false);
      });

      test('canEdit true for ADMIN and STAFF', () {
        expect(_makeUser(role: 'ADMIN').canEdit, true);
        expect(_makeUser(role: 'STAFF').canEdit, true);
      });

      test('canEdit false for CUSTOMER', () {
        expect(_makeUser(role: 'CUSTOMER').canEdit, false);
      });
    });
  });
}

UserModel _makeUser({required String role}) {
  return UserModel(
    id: 'test-id',
    name: 'Test User',
    phone: '0912345678',
    role: role,
  );
}
