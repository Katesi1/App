class HomestayModel {
  final String id;
  final String ownerId;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? mapLink;
  final bool isActive;
  final Map<String, dynamic>? owner;
  final int? roomCount;

  HomestayModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.mapLink,
    this.isActive = true,
    this.owner,
    this.roomCount,
  });

  factory HomestayModel.fromJson(Map<String, dynamic> json) => HomestayModel(
        id: json['id'] ?? '',
        ownerId: json['ownerId'] ?? '',
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
        mapLink: json['mapLink'],
        isActive: json['isActive'] ?? true,
        owner: json['owner'],
        roomCount: json['_count']?['rooms'],
      );

  String get ownerName => owner?['name'] ?? 'N/A';
}
