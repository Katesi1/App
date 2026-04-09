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
  // API mới dùng propertyId, cũ dùng homestayId — giữ tên Dart để không phá UI
  final String homestayId;
  final String name;
  final String code;
  final int? type; // 0=VILLA, 1=HOMESTAY, 2=HOTEL, 3=APARTMENT
  final int bedrooms;
  final int bathrooms;
  final int standardGuests;
  final int maxGuests;
  final String? description;
  final String? address;
  final String? mapLink;
  final List<String> amenities;
  final int? cancellationPolicy; // 0=FLEXIBLE, 1=MODERATE, 2=STRICT
  final double? adultSurcharge;
  final double? childSurcharge;
  final bool isActive;
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
    this.maxGuests = 2,
    this.description,
    this.address,
    this.mapLink,
    this.amenities = const [],
    this.cancellationPolicy,
    this.adultSurcharge,
    this.childSurcharge,
    this.isActive = true,
    this.images = const [],
    this.price,
    this.homestay,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
        id: json['id'] ?? '',
        // Hỗ trợ cả propertyId (API mới) và homestayId (API cũ)
        homestayId: json['propertyId'] ?? json['homestayId'] ?? '',
        name: json['name'] ?? '',
        code: json['code'] ?? '',
        type: json['type'],
        bedrooms: json['bedrooms'] ?? 1,
        bathrooms: json['bathrooms'] ?? 1,
        standardGuests: json['standardGuests'] ?? 2,
        maxGuests: json['maxGuests'] ?? 2,
        description: json['description'],
        address: json['address'],
        mapLink: json['mapLink'],
        amenities: (json['amenities'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        cancellationPolicy: json['cancellationPolicy'],
        adultSurcharge: (json['adultSurcharge'] as num?)?.toDouble(),
        childSurcharge: (json['childSurcharge'] as num?)?.toDouble(),
        isActive: json['isActive'] ?? true,
        images: (json['images'] as List<dynamic>?)
                ?.map((e) => RoomImageModel.fromJson(e))
                .toList() ??
            [],
        price: json['price'] != null
            ? RoomPriceModel.fromJson(json['price'])
            : null,
        // Hỗ trợ cả property (API mới) và homestay (API cũ)
        homestay: (json['property'] ?? json['homestay']) != null
            ? HomestaySimpleModel.fromJson(
                json['property'] ?? json['homestay'])
            : null,
      );

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
