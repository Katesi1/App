class HomestayModel {
  final String id;
  final String ownerId;
  final String name;
  final String address;
  final int? type; // 0=VILLA, 1=HOMESTAY, 2=HOTEL
  final double? latitude;
  final double? longitude;
  final String? mapLink;
  final List<String>? rules;
  final List<String>? services;
  final bool isActive;
  final Map<String, dynamic>? owner;
  final int? roomCount;
  final String? createdAt;
  final String? updatedAt;

  HomestayModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    this.type,
    this.latitude,
    this.longitude,
    this.mapLink,
    this.rules,
    this.services,
    this.isActive = true,
    this.owner,
    this.roomCount,
    this.createdAt,
    this.updatedAt,
  });

  factory HomestayModel.fromJson(Map<String, dynamic> json) => HomestayModel(
        id: json['id'] ?? '',
        ownerId: json['ownerId'] ?? '',
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        type: json['type'] as int?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        mapLink: json['mapLink'],
        rules: (json['rules'] as List?)?.map((e) => e.toString()).toList(),
        services:
            (json['services'] as List?)?.map((e) => e.toString()).toList(),
        isActive: json['isActive'] ?? true,
        owner: json['owner'],
        roomCount: json['_count']?['rooms'],
        createdAt: json['createdAt'],
        updatedAt: json['updatedAt'],
      );

  String get ownerName => owner?['name'] ?? 'N/A';
  String get ownerPhone => owner?['phone'] ?? '';
}
