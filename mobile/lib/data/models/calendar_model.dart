/// Nhóm property cho calendar (từ /calendar/property-groups)
class CalendarPropertyGroup {
  final String id;
  final String name;
  final String? category;
  final int roomCount;

  const CalendarPropertyGroup({
    required this.id,
    required this.name,
    this.category,
    this.roomCount = 0,
  });

  factory CalendarPropertyGroup.fromJson(Map<String, dynamic> json) =>
      CalendarPropertyGroup(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        category: json['category'],
        roomCount: json['roomCount'] ?? 0,
      );
}

/// Trạng thái ngày trong calendar grid
enum CalendarDayStatus { available, hold, booked }

extension CalendarDayStatusX on CalendarDayStatus {
  static CalendarDayStatus fromString(String? value) => switch (value) {
        'HOLD' => CalendarDayStatus.hold,
        'BOOKED' || 'CONFIRMED' => CalendarDayStatus.booked,
        _ => CalendarDayStatus.available,
      };
}

/// Một ngày trong grid calendar
class CalendarDay {
  final String date;
  final double price;
  final CalendarDayStatus status;

  const CalendarDay({
    required this.date,
    required this.price,
    required this.status,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) => CalendarDay(
        date: json['date'] ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        status: CalendarDayStatusX.fromString(json['status']),
      );
}

/// Một phòng trong calendar grid
class CalendarRoomRow {
  final String id;
  final String code;
  final String name;
  final List<CalendarDay> days;

  const CalendarRoomRow({
    required this.id,
    required this.code,
    required this.name,
    this.days = const [],
  });

  factory CalendarRoomRow.fromJson(Map<String, dynamic> json) => CalendarRoomRow(
        id: json['id'] ?? '',
        code: json['code'] ?? '',
        name: json['name'] ?? '',
        days: (json['days'] as List<dynamic>?)
                ?.map((e) => CalendarDay.fromJson(e))
                .toList() ??
            [],
      );
}

/// Response từ /calendar/grid
class CalendarGrid {
  final Map<String, dynamic> propertyGroup;
  final List<CalendarRoomRow> rooms;

  const CalendarGrid({
    required this.propertyGroup,
    this.rooms = const [],
  });

  factory CalendarGrid.fromJson(Map<String, dynamic> json) => CalendarGrid(
        propertyGroup: json['propertyGroup'] ?? {},
        rooms: (json['rooms'] as List<dynamic>?)
                ?.map((e) => CalendarRoomRow.fromJson(e))
                .toList() ??
            [],
      );

  String get propertyGroupName => propertyGroup['name'] ?? '';
}

/// Thông tin liên hệ admin (từ /calendar/admin-contact)
class AdminContact {
  final String name;
  final String phone;
  final String? zaloUrl;

  const AdminContact({
    required this.name,
    required this.phone,
    this.zaloUrl,
  });

  factory AdminContact.fromJson(Map<String, dynamic> json) => AdminContact(
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        zaloUrl: json['zaloUrl'],
      );
}
