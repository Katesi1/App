import '../../core/constants/app_constants.dart';

class BookingModel {
  final String id;
  final String roomId;
  final String? saleId;
  final String? customerId;
  final DateTime checkinDate;
  final DateTime checkoutDate;
  final BookingStatus status;
  final DateTime? holdExpireAt;
  final String? customerName;
  final String? customerPhone;
  final double? depositAmount;
  final int guestCount;
  final String? notes;
  final int holdRemainingSeconds;
  final Map<String, dynamic>? room;
  final Map<String, dynamic>? sale;

  BookingModel({
    required this.id,
    required this.roomId,
    this.saleId,
    this.customerId,
    required this.checkinDate,
    required this.checkoutDate,
    required this.status,
    this.holdExpireAt,
    this.customerName,
    this.customerPhone,
    this.depositAmount,
    this.guestCount = 2,
    this.notes,
    this.holdRemainingSeconds = 0,
    this.room,
    this.sale,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: json['id'] ?? '',
        roomId: json['roomId'] ?? '',
        saleId: json['saleId'],
        customerId: json['customerId'],
        checkinDate: DateTime.parse(json['checkinDate']),
        checkoutDate: DateTime.parse(json['checkoutDate']),
        status: BookingStatusExtension.fromString(json['status'] ?? 'HOLD'),
        holdExpireAt: json['holdExpireAt'] != null
            ? DateTime.parse(json['holdExpireAt'])
            : null,
        customerName: json['customerName'],
        customerPhone: json['customerPhone'],
        depositAmount: (json['depositAmount'] as num?)?.toDouble(),
        guestCount: json['guestCount'] ?? 2,
        notes: json['notes'],
        holdRemainingSeconds: json['holdRemainingSeconds'] ?? 0,
        room: json['room'],
        sale: json['sale'],
      );

  int get nights => checkoutDate.difference(checkinDate).inDays;

  String get roomName => room?['name'] ?? 'N/A';

  // Hỗ trợ cả property (API mới) và homestay (API cũ)
  String get homestayName =>
      room?['property']?['name'] ?? room?['homestay']?['name'] ?? 'N/A';

  String get saleName => sale?['name'] ?? 'N/A';
}

class CalendarBooking {
  final String id;
  final DateTime checkinDate;
  final DateTime checkoutDate;
  final BookingStatus status;
  final String? customerName;
  final int holdRemainingSeconds;
  final Map<String, dynamic>? sale;

  CalendarBooking({
    required this.id,
    required this.checkinDate,
    required this.checkoutDate,
    required this.status,
    this.customerName,
    this.holdRemainingSeconds = 0,
    this.sale,
  });

  factory CalendarBooking.fromJson(Map<String, dynamic> json) =>
      CalendarBooking(
        id: json['id'] ?? '',
        checkinDate: DateTime.parse(json['checkinDate']),
        checkoutDate: DateTime.parse(json['checkoutDate']),
        status: BookingStatusExtension.fromString(json['status'] ?? 'HOLD'),
        customerName: json['customerName'],
        holdRemainingSeconds: json['holdRemainingSeconds'] ?? 0,
        sale: json['sale'],
      );

  String get saleName => sale?['name'] ?? '';

  bool coversDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final c = DateTime(checkinDate.year, checkinDate.month, checkinDate.day);
    final co =
        DateTime(checkoutDate.year, checkoutDate.month, checkoutDate.day);
    return !d.isBefore(c) && d.isBefore(co);
  }
}
