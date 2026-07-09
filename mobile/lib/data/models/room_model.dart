import '../../core/constants/api_constants.dart';

class RoomImageModel {
  final String id;
  final String roomId;
  final String imageUrl;
  final String publicId;
  final bool isCover;
  final int order;

  RoomImageModel({
    required this.id,
    required this.roomId,
    required this.imageUrl,
    required this.publicId,
    this.isCover = false,
    this.order = 0,
  });

  factory RoomImageModel.fromJson(Map<String, dynamic> json) => RoomImageModel(
        id: json['id'] ?? '',
        roomId: json['roomId'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        publicId: json['publicId'] ?? '',
        isCover: json['isCover'] ?? false,
        order: json['order'] ?? 0,
      );
}

class RoomPriceModel {
  final String id;
  final String roomId;
  final double weekdayPrice;
  final double fridayPrice;
  final double saturdayPrice;
  final double holidayPrice;

  RoomPriceModel({
    required this.id,
    required this.roomId,
    required this.weekdayPrice,
    required this.fridayPrice,
    required this.saturdayPrice,
    required this.holidayPrice,
  });

  factory RoomPriceModel.fromJson(Map<String, dynamic> json) => RoomPriceModel(
        id: json['id'] ?? '',
        roomId: json['roomId'] ?? '',
        weekdayPrice: (json['weekdayPrice'] ?? 0).toDouble(),
        fridayPrice: (json['fridayPrice'] ?? 0).toDouble(),
        saturdayPrice: (json['saturdayPrice'] ?? 0).toDouble(),
        holidayPrice: (json['holidayPrice'] ?? 0).toDouble(),
      );

  double get minPrice {
    final prices = [weekdayPrice, fridayPrice, saturdayPrice];
    return prices.reduce((a, b) => a < b ? a : b);
  }
}

class HomestaySimpleModel {
  final String id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? mapLink;

  HomestaySimpleModel({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.mapLink,
  });

  factory HomestaySimpleModel.fromJson(Map<String, dynamic> json) =>
      HomestaySimpleModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        mapLink: json['mapLink'],
      );
}

class RoomModel {
  final String id;
  // New API uses propertyId; old API uses homestayId — keep the Dart name to avoid breaking UI.
  final String homestayId;
  final String name;
  final String code;
  final int? type; // 0=VILLA, 1=HOMESTAY, 2=HOTEL
  final int bedrooms;
  final int bathrooms;
  final int standardGuests;
  // Sức chứa trẻ em tiêu chuẩn (đã bao trong giá). BE v1.27+, mặc định 0.
  final int standardChildren;
  final int maxGuests;
  final String? description;
  final String? address;
  final String? mapLink;
  final List<String> amenities;
  final int? cancellationPolicy; // 0=FLEXIBLE, 1=MODERATE, 2=STRICT
  final String? view; // "sea" = sea view, "city" = city view, null = none
  final String? rules; // House rules (single text string)
  final List<String> services; // Paid services
  final double? adultSurcharge;
  final double? childSurcharge;
  final bool isActive;
  // Trạng thái kiểm duyệt cơ sở: pending | approved | rejected | suspended.
  // Mặc định 'approved' (BE tạo property mới = approved; legacy đã sweep).
  final String moderationStatus;
  // Đánh giá denormalized từ BE (ratingAvg=0 khi reviewCount=0). Spec §4.5/§4.14.
  final double ratingAvg;
  final int reviewCount;
  final List<RoomImageModel> images;
  final RoomPriceModel? price;
  final HomestaySimpleModel? homestay;

  RoomModel({
    required this.id,
    required this.homestayId,
    required this.name,
    required this.code,
    this.type,
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.standardGuests = 2,
    this.standardChildren = 0,
    this.maxGuests = 2,
    this.description,
    this.address,
    this.mapLink,
    this.amenities = const [],
    this.cancellationPolicy,
    this.view,
    this.rules,
    this.services = const [],
    this.adultSurcharge,
    this.childSurcharge,
    this.isActive = true,
    this.moderationStatus = 'approved',
    this.ratingAvg = 0,
    this.reviewCount = 0,
    this.images = const [],
    this.price,
    this.homestay,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
        id: json['id'] ?? '',
        // Support both propertyId (new API) and homestayId (old API).
        homestayId: json['propertyId'] ?? json['homestayId'] ?? '',
        name: json['name'] ?? '',
        code: json['code'] ?? '',
        type: json['type'],
        bedrooms: json['bedrooms'] ?? 1,
        bathrooms: json['bathrooms'] ?? 1,
        standardGuests: json['standardGuests'] ?? 2,
        standardChildren: json['standardChildren'] ?? 0,
        maxGuests: json['maxGuests'] ?? 2,
        description: json['description'],
        address: json['address'],
        mapLink: json['mapLink'],
        amenities: (json['amenities'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        cancellationPolicy: json['cancellationPolicy'],
        view: json['view'],
        rules: json['rules'],
        services: (json['services'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        adultSurcharge: (json['adultSurcharge'] as num?)?.toDouble(),
        childSurcharge: (json['childSurcharge'] as num?)?.toDouble(),
        isActive: json['isActive'] ?? true,
        moderationStatus: json['moderationStatus'] ?? 'approved',
        ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        images: (json['images'] as List<dynamic>?)
                ?.map((e) => RoomImageModel.fromJson(e))
                .toList() ??
            [],
        // New API returns flat price (weekdayPrice/weekendPrice/holidayPrice at root).
        // Old API returns a nested object json['price']. Both supported.
        price: json['price'] != null
            ? RoomPriceModel.fromJson(json['price'])
            : (json['weekdayPrice'] != null ||
                    json['weekendPrice'] != null ||
                    json['holidayPrice'] != null)
                ? RoomPriceModel(
                    id: '',
                    roomId: json['id'] ?? '',
                    weekdayPrice:
                        (json['weekdayPrice'] as num?)?.toDouble() ?? 0,
                    // New API has a single weekendPrice — assign to both friday + saturday
                    fridayPrice:
                        (json['weekendPrice'] as num?)?.toDouble() ?? 0,
                    saturdayPrice:
                        (json['weekendPrice'] as num?)?.toDouble() ?? 0,
                    holidayPrice:
                        (json['holidayPrice'] as num?)?.toDouble() ?? 0,
                  )
                : null,
        // Support both property (new API) and homestay (old API).
        homestay: (json['property'] ?? json['homestay']) != null
            ? HomestaySimpleModel.fromJson(json['property'] ?? json['homestay'])
            : null,
      );

  /// Chỉ cho share khi phòng đang hoạt động VÀ đã được duyệt — khớp với
  /// visibility rule của web khách (isActive && moderationStatus=='approved').
  /// Nếu không thoả, link sẽ 404 trên web nên ẩn/disable nút share.
  bool get canShare => isActive && moderationStatus == 'approved';

  /// URL web preview cho khách xem thông tin phòng (không kèm giá).
  String get shareUrl => ApiConstants.propertyShareUrl(id);

  /// Có đánh giá để hiển thị badge sao không (ẩn khi chưa ai review — spec §4.14).
  bool get hasRating => reviewCount > 0;

  String? get coverImageUrl {
    if (images.isEmpty) return null;
    final cover = images.where((i) => i.isCover).firstOrNull;
    return cover?.imageUrl ?? images.first.imageUrl;
  }

  String get priceDisplay {
    if (price == null) return 'Chưa có giá';
    return '${_formatPrice(price!.minPrice)}đ/đêm';
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}tr';
    }
    return '${(price / 1000).toStringAsFixed(0)}k';
  }
}
