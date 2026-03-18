import '../../core/constants/app_constants.dart';

class BookingModel {
  final String id;
  final String roomId;
  final String saleId;
  final DateTime checkinDate;
  final DateTime checkoutDate;
  final BookingStatus status;
  final DateTime? holdExpireAt;
  final String? customerName;
  final String? customerPhone;
  final double? depositAmount;
  final String? notes;
  final int holdRemainingSeconds;
  final Map<String, dynamic>? room;
  final Map<String, dynamic>? sale;

  BookingModel({
    required this.id,
    required this.roomId,
    required this.saleId,
    required this.checkinDate,
    required this.checkoutDate,
    required this.status,
    this.holdExpireAt,
    this.customerName,
    this.customerPhone,
    this.depositAmount,
    this.notes,
    this.holdRemainingSeconds = 0,
    this.room,
    this.sale,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: json['id'] ?? '',
        roomId: json['roomId'] ?? '',
        saleId: json['saleId'] ?? '',
        checkinDate: DateTime.parse(json['checkinDate']),
        checkoutDate: DateTime.parse(json['checkoutDate']),
        status: BookingStatusExtension.fromString(json['status'] ?? 'HOLD'),
        holdExpireAt: json['holdExpireAt'] != null
            ? DateTime.parse(json['holdExpireAt'])
            : null,
        customerName: json['customerName'],
        customerPhone: json['customerPhone'],
        depositAmount: (json['depositAmount'] ?? 0).toDouble(),
        notes: json['notes'],
        holdRemainingSeconds: json['holdRemainingSeconds'] ?? 0,
        room: json['room'],
        sale: json['sale'],
      );

  int get nights => checkoutDate.difference(checkinDate).inDays;

  String get roomName => room?['name'] ?? 'N/A';
  String get homestayName => room?['homestay']?['name'] ?? 'N/A';
  String get saleName => sale?['name'] ?? 'N/A';
}

class CalendarBooking {
  final String id;
  final DateTime checkinDate;
  final DateTime checkoutDate;
  final BookingStatus status;
  final String? customerName;
  final int holdRemainingSeconds;

  CalendarBooking({
    required this.id,
    required this.checkinDate,
    required this.checkoutDate,
    required this.status,
    this.customerName,
    this.holdRemainingSeconds = 0,
  });

  factory CalendarBooking.fromJson(Map<String, dynamic> json) =>
      CalendarBooking(
        id: json['id'] ?? '',
        checkinDate: DateTime.parse(json['checkinDate']),
        checkoutDate: DateTime.parse(json['checkoutDate']),
        status: BookingStatusExtension.fromString(json['status'] ?? 'HOLD'),
        customerName: json['customerName'],
        holdRemainingSeconds: json['holdRemainingSeconds'] ?? 0,
      );

  bool coversDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final c = DateTime(checkinDate.year, checkinDate.month, checkinDate.day);
    final co =
        DateTime(checkoutDate.year, checkoutDate.month, checkoutDate.day);
    return !d.isBefore(c) && d.isBefore(co);
  }
}
