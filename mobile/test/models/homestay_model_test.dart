import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/homestay_model.dart';

void main() {
  group('HomestayModel.fromJson', () {
    test('parses all fields correctly when all present', () {
      final json = {
        'id': 'h-1',
        'ownerId': 'owner-1',
        'name': 'Villa Hạ Long',
        'code': 'HL001',
        'address': '123 Hạ Long, Quảng Ninh',
        'type': 0,
        'latitude': 20.951,
        'longitude': 107.073,
        'mapLink': 'https://maps.google.com/?q=20.951,107.073',
        'rules': ['Không hút thuốc', 'Không thú cưng'],
        'services': ['WiFi', 'Điều hòa'],
        'isActive': true,
        '_count': {'rooms': 5},
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-04-01T00:00:00.000Z',
      };

      final model = HomestayModel.fromJson(json);

      expect(model.id, 'h-1');
      expect(model.ownerId, 'owner-1');
      expect(model.name, 'Villa Hạ Long');
      expect(model.code, 'HL001');
      expect(model.address, '123 Hạ Long, Quảng Ninh');
      expect(model.type, 0);
      expect(model.latitude, closeTo(20.951, 0.001));
      expect(model.longitude, closeTo(107.073, 0.001));
      expect(model.mapLink, 'https://maps.google.com/?q=20.951,107.073');
      expect(model.rules, ['Không hút thuốc', 'Không thú cưng']);
      expect(model.services, ['WiFi', 'Điều hòa']);
      expect(model.isActive, true);
      expect(model.roomCount, 5);
      expect(model.createdAt, '2026-01-01T00:00:00.000Z');
    });

    test('id falls back to empty string when missing', () {
      final json = {
        'ownerId': 'owner-1',
        'name': 'Test',
        'address': 'Somewhere',
      };

      final model = HomestayModel.fromJson(json);

      expect(model.id, '');
    });

    test('ownerId falls back to empty string when missing', () {
      final json = {
        'id': 'h-2',
        'name': 'Test',
        'address': 'Somewhere',
      };

      final model = HomestayModel.fromJson(json);

      expect(model.ownerId, '');
    });

    test('name falls back to empty string when missing', () {
      final json = {
        'id': 'h-3',
        'ownerId': 'owner-1',
        'address': 'Somewhere',
      };

      final model = HomestayModel.fromJson(json);

      expect(model.name, '');
    });

    test('code falls back to empty string when missing', () {
      final json = {
        'id': 'h-4',
        'ownerId': 'o',
        'name': 'N',
        'address': 'A',
      };

      final model = HomestayModel.fromJson(json);

      expect(model.code, '');
    });

    test('isActive defaults to true when missing', () {
      final json = {
        'id': 'h-5',
        'ownerId': 'o',
        'name': 'N',
        'address': 'A',
      };

      final model = HomestayModel.fromJson(json);

      expect(model.isActive, true);
    });

    test('nullable fields are null when missing', () {
      final json = {
        'id': 'h-6',
        'ownerId': 'o',
        'name': 'N',
        'address': 'A',
      };

      final model = HomestayModel.fromJson(json);

      expect(model.type, isNull);
      expect(model.latitude, isNull);
      expect(model.longitude, isNull);
      expect(model.mapLink, isNull);
      expect(model.rules, isNull);
      expect(model.services, isNull);
      expect(model.owner, isNull);
      expect(model.roomCount, isNull);
    });

    test('roomCount is null when _count is missing', () {
      final json = {
        'id': 'h-7',
        'ownerId': 'o',
        'name': 'N',
        'address': 'A',
      };

      final model = HomestayModel.fromJson(json);

      expect(model.roomCount, isNull);
    });

    test('roomCount is null when _count.rooms is missing', () {
      final json = {
        'id': 'h-8',
        'ownerId': 'o',
        'name': 'N',
        'address': 'A',
        '_count': <String, dynamic>{},
      };

      final model = HomestayModel.fromJson(json);

      expect(model.roomCount, isNull);
    });

    test('rules parses List correctly', () {
      final json = {
        'id': 'h-9',
        'ownerId': 'o',
        'name': 'N',
        'address': 'A',
        'rules': ['No smoking', 'No pets'],
      };

      final model = HomestayModel.fromJson(json);

      expect(model.rules, ['No smoking', 'No pets']);
    });

    test('rules wraps single String in a list', () {
      final json = {
        'id': 'h-10',
        'ownerId': 'o',
        'name': 'N',
        'address': 'A',
        'rules': 'No smoking',
      };

      final model = HomestayModel.fromJson(json);

      expect(model.rules, ['No smoking']);
    });

    test('services parses List correctly', () {
      final json = {
        'id': 'h-11',
        'ownerId': 'o',
        'name': 'N',
        'address': 'A',
        'services': ['WiFi', 'Pool'],
      };

      final model = HomestayModel.fromJson(json);

      expect(model.services, ['WiFi', 'Pool']);
    });

    test('services wraps single String in a list', () {
      final json = {
        'id': 'h-12',
        'ownerId': 'o',
        'name': 'N',
        'address': 'A',
        'services': 'WiFi',
      };

      final model = HomestayModel.fromJson(json);

      expect(model.services, ['WiFi']);
    });
  });

  group('HomestayModel owner getters', () {
    test('ownerName returns name from owner map', () {
      final json = {
        'id': 'h-20',
        'ownerId': 'o',
        'name': 'N',
        'address': 'A',
        'owner': {'id': 'o', 'name': 'Nguyễn Văn A', 'phone': '0912345678'},
      };

      final model = HomestayModel.fromJson(json);

      expect(model.ownerName, 'Nguyễn Văn A');
    });

    test('ownerPhone returns phone from owner map', () {
      final json = {
        'id': 'h-21',
        'ownerId': 'o',
        'name': 'N',
        'address': 'A',
        'owner': {'id': 'o', 'name': 'Nguyễn Văn A', 'phone': '0912345678'},
      };

      final model = HomestayModel.fromJson(json);

      expect(model.ownerPhone, '0912345678');
    });

    test('ownerName returns N/A when owner is null', () {
      final json = {
        'id': 'h-22',
        'ownerId': 'o',
        'name': 'N',
        'address': 'A',
      };

      final model = HomestayModel.fromJson(json);

      expect(model.ownerName, 'N/A');
    });

    test('ownerPhone returns empty string when owner is null', () {
      final json = {
        'id': 'h-23',
        'ownerId': 'o',
        'name': 'N',
        'address': 'A',
      };

      final model = HomestayModel.fromJson(json);

      expect(model.ownerPhone, '');
    });

    test('ownerName returns N/A when owner map has no name key', () {
      final json = {
        'id': 'h-24',
        'ownerId': 'o',
        'name': 'N',
        'address': 'A',
        'owner': {'id': 'o'},
      };

      final model = HomestayModel.fromJson(json);

      expect(model.ownerName, 'N/A');
    });

    test('ownerPhone returns empty string when owner map has no phone key', () {
      final json = {
        'id': 'h-25',
        'ownerId': 'o',
        'name': 'N',
        'address': 'A',
        'owner': {'id': 'o', 'name': 'Test'},
      };

      final model = HomestayModel.fromJson(json);

      expect(model.ownerPhone, '');
    });
  });
}
