import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/calendar_model.dart';

void main() {
  // ─────────────────────────────────────────────
  // CalendarDayStatus.fromString
  // ─────────────────────────────────────────────
  group('CalendarDayStatus.fromString', () {
    test('parses "available" correctly', () {
      // Arrange
      const input = 'available';

      // Act
      final status = CalendarDayStatusX.fromString(input);

      // Assert
      expect(status, CalendarDayStatus.available);
    });

    test('parses "hold" correctly', () {
      // Arrange
      const input = 'hold';

      // Act
      final status = CalendarDayStatusX.fromString(input);

      // Assert
      expect(status, CalendarDayStatus.hold);
    });

    test('parses "booked" correctly', () {
      // Arrange
      const input = 'booked';

      // Act
      final status = CalendarDayStatusX.fromString(input);

      // Assert
      expect(status, CalendarDayStatus.booked);
    });

    test('parses "confirmed" as booked', () {
      // Arrange
      const input = 'confirmed';

      // Act
      final status = CalendarDayStatusX.fromString(input);

      // Assert
      expect(status, CalendarDayStatus.booked);
    });

    test('parses "locked" correctly', () {
      // Arrange
      const input = 'locked';

      // Act
      final status = CalendarDayStatusX.fromString(input);

      // Assert
      expect(status, CalendarDayStatus.locked);
    });

    test('null falls back to available without crash', () {
      // Act
      final status = CalendarDayStatusX.fromString(null);

      // Assert
      expect(status, CalendarDayStatus.available);
    });

    test('unknown string falls back to available', () {
      // Arrange
      const input = 'invalid_xyz';

      // Act
      final status = CalendarDayStatusX.fromString(input);

      // Assert
      expect(status, CalendarDayStatus.available);
    });

    test('uppercase input is case-insensitive', () {
      // Arrange
      const input = 'HOLD';

      // Act
      final status = CalendarDayStatusX.fromString(input);

      // Assert
      expect(status, CalendarDayStatus.hold);
    });
  });

  // ─────────────────────────────────────────────
  // CalendarDay.fromJson
  // ─────────────────────────────────────────────
  group('CalendarDay.fromJson', () {
    test('parses full json correctly', () {
      // Arrange
      final json = {
        'date': '2026-05-01',
        'price': 800000,
        'status': 'available',
      };

      // Act
      final day = CalendarDay.fromJson(json);

      // Assert
      expect(day.date, '2026-05-01');
      expect(day.price, 800000.0);
      expect(day.status, CalendarDayStatus.available);
    });

    test('parses held day correctly', () {
      // Arrange
      final json = {
        'date': '2026-05-02',
        'price': 1000000,
        'status': 'hold',
      };

      // Act
      final day = CalendarDay.fromJson(json);

      // Assert
      expect(day.status, CalendarDayStatus.hold);
    });

    test('missing fields fall back to defaults', () {
      // Arrange — empty json
      final json = <String, dynamic>{};

      // Act
      final day = CalendarDay.fromJson(json);

      // Assert
      expect(day.date, '');
      expect(day.price, 0.0);
      expect(day.status, CalendarDayStatus.available);
    });

    test('null status falls back to available', () {
      // Arrange
      final json = {
        'date': '2026-05-10',
        'price': 500000,
        'status': null,
      };

      // Act
      final day = CalendarDay.fromJson(json);

      // Assert
      expect(day.status, CalendarDayStatus.available);
    });

    test('price as integer is parsed to double', () {
      // Arrange
      final json = {
        'date': '2026-05-15',
        'price': 750000,
        'status': 'available',
      };

      // Act
      final day = CalendarDay.fromJson(json);

      // Assert
      expect(day.price, isA<double>());
      expect(day.price, 750000.0);
    });
  });

  // ─────────────────────────────────────────────
  // CalendarRoomRow.fromJson
  // ─────────────────────────────────────────────
  group('CalendarRoomRow.fromJson', () {
    test('parses full json with days list', () {
      // Arrange
      final json = {
        'id': 'room-1',
        'code': 'P.101',
        'name': 'Deluxe Ocean',
        'type': 0,
        'address': 'Hạ Long',
        'view': 'sea',
        'days': [
          {'date': '2026-05-01', 'price': 800000, 'status': 'available'},
          {'date': '2026-05-02', 'price': 800000, 'status': 'hold'},
          {'date': '2026-05-03', 'price': 800000, 'status': 'booked'},
        ],
      };

      // Act
      final row = CalendarRoomRow.fromJson(json);

      // Assert
      expect(row.id, 'room-1');
      expect(row.code, 'P.101');
      expect(row.name, 'Deluxe Ocean');
      expect(row.type, 0);
      expect(row.address, 'Hạ Long');
      expect(row.view, 'sea');
      expect(row.days.length, 3);
      expect(row.days[0].status, CalendarDayStatus.available);
      expect(row.days[1].status, CalendarDayStatus.hold);
      expect(row.days[2].status, CalendarDayStatus.booked);
    });

    test('parses json with empty days list', () {
      // Arrange
      final json = {
        'id': 'room-2',
        'code': 'P.102',
        'name': 'Standard Room',
        'days': <dynamic>[],
      };

      // Act
      final row = CalendarRoomRow.fromJson(json);

      // Assert
      expect(row.id, 'room-2');
      expect(row.days, isEmpty);
    });

    test('missing days key falls back to empty list', () {
      // Arrange — no "days" key
      final json = {
        'id': 'room-3',
        'code': 'P.103',
        'name': 'Suite',
      };

      // Act
      final row = CalendarRoomRow.fromJson(json);

      // Assert
      expect(row.days, isEmpty);
    });

    test('optional fields are nullable when absent', () {
      // Arrange
      final json = {
        'id': 'room-4',
        'code': 'P.104',
        'name': 'Basic Room',
      };

      // Act
      final row = CalendarRoomRow.fromJson(json);

      // Assert
      expect(row.type, isNull);
      expect(row.address, isNull);
      expect(row.view, isNull);
    });
  });

  // ─────────────────────────────────────────────
  // CalendarGrid.fromJson
  // ─────────────────────────────────────────────
  group('CalendarGrid.fromJson', () {
    test('parses properties list correctly', () {
      // Arrange
      final json = {
        'properties': [
          {
            'id': 'room-1',
            'code': 'P.101',
            'name': 'Room A',
            'days': <dynamic>[],
          },
          {
            'id': 'room-2',
            'code': 'P.102',
            'name': 'Room B',
            'days': <dynamic>[],
          },
        ],
      };

      // Act
      final grid = CalendarGrid.fromJson(json);

      // Assert
      expect(grid.properties.length, 2);
      expect(grid.properties[0].id, 'room-1');
      expect(grid.properties[1].id, 'room-2');
    });

    test('empty properties list parses correctly', () {
      // Arrange
      final json = {
        'properties': <dynamic>[],
      };

      // Act
      final grid = CalendarGrid.fromJson(json);

      // Assert
      expect(grid.properties, isEmpty);
    });

    test('missing properties key falls back to empty list', () {
      // Arrange — no "properties" key
      final json = <String, dynamic>{};

      // Act
      final grid = CalendarGrid.fromJson(json);

      // Assert
      expect(grid.properties, isEmpty);
    });

    test('days inside properties are parsed correctly', () {
      // Arrange
      final json = {
        'properties': [
          {
            'id': 'room-1',
            'code': 'P.101',
            'name': 'Room A',
            'days': [
              {'date': '2026-06-01', 'price': 900000, 'status': 'booked'},
            ],
          },
        ],
      };

      // Act
      final grid = CalendarGrid.fromJson(json);

      // Assert
      expect(grid.properties[0].days.length, 1);
      expect(grid.properties[0].days[0].status, CalendarDayStatus.booked);
      expect(grid.properties[0].days[0].price, 900000.0);
    });
  });

  // ─────────────────────────────────────────────
  // AdminContact.fromJson
  // ─────────────────────────────────────────────
  group('AdminContact.fromJson', () {
    test('parses full json correctly', () {
      // Arrange
      final json = {
        'name': 'Admin Hạ Long',
        'phone': '0912345678',
        'zaloUrl': 'https://zalo.me/123',
      };

      // Act
      final contact = AdminContact.fromJson(json);

      // Assert
      expect(contact.name, 'Admin Hạ Long');
      expect(contact.phone, '0912345678');
      expect(contact.zaloUrl, 'https://zalo.me/123');
    });

    test('zaloUrl is nullable when absent', () {
      // Arrange
      final json = {
        'name': 'Admin',
        'phone': '0900000000',
      };

      // Act
      final contact = AdminContact.fromJson(json);

      // Assert
      expect(contact.zaloUrl, isNull);
    });
  });
}
