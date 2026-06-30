import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/room_model.dart';

void main() {
  group('RoomModel', () {
    test('fromJson parses full data', () {
      final json = {
        'id': 'r-1',
        'homestayId': 'hs-1',
        'name': 'Deluxe Ocean',
        'code': 'P.101',
        'bedrooms': 2,
        'maxGuests': 4,
        'description': 'View biển đẹp',
        'isActive': true,
        'images': [
          {
            'id': 'img-1',
            'roomId': 'r-1',
            'imageUrl': 'https://example.com/1.jpg',
            'publicId': 'p1',
            'isCover': true,
            'order': 0,
          },
          {
            'id': 'img-2',
            'roomId': 'r-1',
            'imageUrl': 'https://example.com/2.jpg',
            'publicId': 'p2',
            'isCover': false,
            'order': 1,
          },
        ],
        'price': {
          'id': 'pr-1',
          'roomId': 'r-1',
          'weekdayPrice': 800000,
          'fridayPrice': 1000000,
          'saturdayPrice': 1200000,
          'holidayPrice': 1500000,
        },
        'homestay': {
          'id': 'hs-1',
          'name': 'HL Resort',
          'address': 'Hạ Long',
        },
      };

      final room = RoomModel.fromJson(json);

      expect(room.id, 'r-1');
      expect(room.name, 'Deluxe Ocean');
      expect(room.code, 'P.101');
      expect(room.bedrooms, 2);
      expect(room.maxGuests, 4);
      expect(room.images.length, 2);
      expect(room.price, isNotNull);
      expect(room.homestay, isNotNull);
      expect(room.homestay!.name, 'HL Resort');
    });

    test('coverImageUrl returns cover image', () {
      final room = RoomModel.fromJson({
        'id': 'r-1',
        'homestayId': 'hs-1',
        'name': 'Test',
        'code': 'P.1',
        'images': [
          {
            'id': 'img-1',
            'roomId': 'r-1',
            'imageUrl': 'https://example.com/normal.jpg',
            'publicId': 'p1',
            'isCover': false,
          },
          {
            'id': 'img-2',
            'roomId': 'r-1',
            'imageUrl': 'https://example.com/cover.jpg',
            'publicId': 'p2',
            'isCover': true,
          },
        ],
      });

      expect(room.coverImageUrl, 'https://example.com/cover.jpg');
    });

    test('coverImageUrl returns first image when no cover', () {
      final room = RoomModel.fromJson({
        'id': 'r-1',
        'homestayId': 'hs-1',
        'name': 'Test',
        'code': 'P.1',
        'images': [
          {
            'id': 'img-1',
            'roomId': 'r-1',
            'imageUrl': 'https://example.com/first.jpg',
            'publicId': 'p1',
            'isCover': false,
          },
        ],
      });

      expect(room.coverImageUrl, 'https://example.com/first.jpg');
    });

    test('coverImageUrl returns null when no images', () {
      final room = RoomModel.fromJson({
        'id': 'r-1',
        'homestayId': 'hs-1',
        'name': 'Test',
        'code': 'P.1',
      });

      expect(room.coverImageUrl, isNull);
    });

    test('priceDisplay shows formatted price', () {
      final room = RoomModel.fromJson({
        'id': 'r-1',
        'homestayId': 'hs-1',
        'name': 'Test',
        'code': 'P.1',
        'price': {
          'id': 'pr-1',
          'roomId': 'r-1',
          'weekdayPrice': 800000,
          'fridayPrice': 1000000,
          'saturdayPrice': 1200000,
          'holidayPrice': 1500000,
        },
      });

      expect(room.priceDisplay, '800kđ/đêm');
    });

    test('priceDisplay shows "Chưa có giá" when no price', () {
      final room = RoomModel.fromJson({
        'id': 'r-1',
        'homestayId': 'hs-1',
        'name': 'Test',
        'code': 'P.1',
      });

      expect(room.priceDisplay, 'Chưa có giá');
    });

    test('defaults for missing fields', () {
      final room = RoomModel.fromJson({});

      expect(room.id, '');
      expect(room.homestayId, '');
      expect(room.name, '');
      expect(room.code, '');
      expect(room.bedrooms, 1);
      expect(room.maxGuests, 2);
      expect(room.isActive, true);
      expect(room.images, isEmpty);
      expect(room.price, isNull);
      expect(room.homestay, isNull);
    });
  });

  group('RoomModel share link', () {
    RoomModel build({bool? isActive, String? moderationStatus}) =>
        RoomModel.fromJson({
          'id': 'r-1',
          'homestayId': 'hs-1',
          'name': 'Test',
          'code': 'P.1',
          if (isActive != null) 'isActive': isActive,
          if (moderationStatus != null) 'moderationStatus': moderationStatus,
        });

    test('moderationStatus defaults to approved when missing', () {
      expect(build().moderationStatus, 'approved');
    });

    test('shareUrl points to preview web with property id', () {
      expect(build().shareUrl, 'https://preview.halong24h.com/r-1');
    });

    test('canShare true when active and approved', () {
      expect(build(isActive: true, moderationStatus: 'approved').canShare,
          isTrue);
    });

    test('canShare false when inactive', () {
      expect(build(isActive: false, moderationStatus: 'approved').canShare,
          isFalse);
    });

    test('canShare false when not approved', () {
      for (final status in ['pending', 'rejected', 'suspended']) {
        expect(build(isActive: true, moderationStatus: status).canShare, isFalse,
            reason: 'status=$status should not be shareable');
      }
    });
  });

  group('RoomPriceModel', () {
    test('minPrice returns lowest non-holiday price', () {
      final price = RoomPriceModel.fromJson({
        'id': 'pr-1',
        'roomId': 'r-1',
        'weekdayPrice': 800000,
        'fridayPrice': 1000000,
        'saturdayPrice': 1200000,
        'holidayPrice': 1500000,
      });

      expect(price.minPrice, 800000);
    });

    test('minPrice when friday is cheapest', () {
      final price = RoomPriceModel.fromJson({
        'id': 'pr-1',
        'roomId': 'r-1',
        'weekdayPrice': 900000,
        'fridayPrice': 700000,
        'saturdayPrice': 1200000,
        'holidayPrice': 1500000,
      });

      expect(price.minPrice, 700000);
    });
  });
}
