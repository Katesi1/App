class HomestayModel {
  final String id;
  final String ownerId;
  final String name;
  final String code;
  final String address;
  final int? type; // 0=VILLA, 1=HOMESTAY, 2=HOTEL
  final double? latitude;
  final double? longitude;
  final String? mapLink;
  final List<String>? rules;
  final List<String>? services;
  final bool isActive;
  // Đánh giá denormalized từ BE (ratingAvg=0 khi reviewCount=0). Spec §4.5.
  final double ratingAvg;
  final int reviewCount;
  final Map<String, dynamic>? owner;
  final int? roomCount;
  final String? createdAt;
  final String? updatedAt;

  HomestayModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.code = '',
    required this.address,
    this.type,
    this.latitude,
    this.longitude,
    this.mapLink,
    this.rules,
    this.services,
    this.isActive = true,
    this.ratingAvg = 0,
    this.reviewCount = 0,
    this.owner,
    this.roomCount,
    this.createdAt,
    this.updatedAt,
  });

  factory HomestayModel.fromJson(Map<String, dynamic> json) => HomestayModel(
        id: json['id'] ?? '',
        ownerId: json['ownerId'] ?? '',
        name: json['name'] ?? '',
        code: json['code'] ?? '',
        address: json['address'] ?? '',
        type: json['type'] as int?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        mapLink: json['mapLink'],
        rules: json['rules'] is List
            ? (json['rules'] as List).map((e) => e.toString()).toList()
            : json['rules'] is String
                ? [json['rules'] as String]
                : null,
        services: json['services'] is List
            ? (json['services'] as List).map((e) => e.toString()).toList()
            : json['services'] is String
                ? [json['services'] as String]
                : null,
        isActive: json['isActive'] ?? true,
        ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        owner: json['owner'],
        roomCount: json['_count']?['rooms'],
        createdAt: json['createdAt'],
        updatedAt: json['updatedAt'],
      );

  String get ownerName => owner?['name'] ?? 'N/A';
  String get ownerPhone => owner?['phone'] ?? '';

  /// Có thông tin chủ nhà để hiển thị cho quản lý cấp hệ thống không
  /// (BE chỉ nhúng `owner` cho ADMIN / SALE hệ thống).
  bool get hasOwnerInfo => (owner?['name'] as String?)?.isNotEmpty == true;

  /// Có đánh giá để hiển thị badge sao không (ẩn khi chưa ai review — spec §4.5).
  bool get hasRating => reviewCount > 0;
}
