/// Trạng thái ngày trong calendar grid
enum CalendarDayStatus { available, hold, booked, locked }

extension CalendarDayStatusX on CalendarDayStatus {
  static CalendarDayStatus fromString(String? value) =>
      switch (value?.toLowerCase()) {
        'hold' => CalendarDayStatus.hold,
        'booked' || 'confirmed' => CalendarDayStatus.booked,
        'locked' => CalendarDayStatus.locked,
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

/// Một property (phòng/căn) trong calendar grid
class CalendarRoomRow {
  final String id;
  final String code;
  final String name;
  final int? type;
  final String? address;
  final List<CalendarDay> days;

  const CalendarRoomRow({
    required this.id,
    required this.code,
    required this.name,
    this.type,
    this.address,
    this.days = const [],
  });

  factory CalendarRoomRow.fromJson(Map<String, dynamic> json) =>
      CalendarRoomRow(
        id: json['id'] ?? '',
        code: json['code'] ?? '',
        name: json['name'] ?? '',
        type: json['type'] as int?,
        address: json['address'],
        days: (json['days'] as List<dynamic>?)
                ?.map((e) => CalendarDay.fromJson(e))
                .toList() ??
            [],
      );
}

/// Response từ /calendar/grid và /calendar/public-grid
class CalendarGrid {
  final List<CalendarRoomRow> properties;

  const CalendarGrid({this.properties = const []});

  factory CalendarGrid.fromJson(Map<String, dynamic> json) => CalendarGrid(
        properties: (json['properties'] as List<dynamic>?)
                ?.map((e) => CalendarRoomRow.fromJson(e))
                .toList() ??
            [],
      );
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
