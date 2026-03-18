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
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
        mapLink: json['mapLink'],
      );
}

class RoomModel {
  final String id;
  final String homestayId;
  final String name;
  final String code;
  final int bedrooms;
  final int maxGuests;
  final String? description;
  final bool isActive;
  final List<RoomImageModel> images;
  final RoomPriceModel? price;
  final HomestaySimpleModel? homestay;

  RoomModel({
    required this.id,
    required this.homestayId,
    required this.name,
    required this.code,
    this.bedrooms = 1,
    this.maxGuests = 2,
    this.description,
    this.isActive = true,
    this.images = const [],
    this.price,
    this.homestay,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) => RoomModel(
        id: json['id'] ?? '',
        homestayId: json['homestayId'] ?? '',
        name: json['name'] ?? '',
        code: json['code'] ?? '',
        bedrooms: json['bedrooms'] ?? 1,
        maxGuests: json['maxGuests'] ?? 2,
        description: json['description'],
        isActive: json['isActive'] ?? true,
        images: (json['images'] as List<dynamic>?)
                ?.map((e) => RoomImageModel.fromJson(e))
                .toList() ??
            [],
        price: json['price'] != null
            ? RoomPriceModel.fromJson(json['price'])
            : null,
        homestay: json['homestay'] != null
            ? HomestaySimpleModel.fromJson(json['homestay'])
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
