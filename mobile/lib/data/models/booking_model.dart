import '../../core/constants/app_constants.dart';

// cancelledByRole values: 0=ADMIN, 1=OWNER, 2=SALE, 3=CUSTOMER, null=system/cron
class BookingModel {
  final String id;
  final String propertyId;
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
  final Map<String, dynamic>? property;
  final Map<String, dynamic>? sale;
  // Cancellation tracking (v1.14) — null on non-cancelled bookings or pre-migration rows
  final DateTime? cancelledAt;
  final String? cancelledByUserId;
  final int? cancelledByRole;
  final String? cancelledReason;

  BookingModel({
    required this.id,
    required this.propertyId,
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
    this.property,
    this.sale,
    this.cancelledAt,
    this.cancelledByUserId,
    this.cancelledByRole,
    this.cancelledReason,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: json['id'] ?? '',
        propertyId: json['propertyId'] ?? '',
        saleId: json['saleId'],
        customerId: json['customerId'],
        checkinDate: DateTime.parse(json['checkinDate']),
        checkoutDate: DateTime.parse(json['checkoutDate']),
        status: BookingStatusExtension.fromInt(json['status'] ?? 0),
        holdExpireAt: json['holdExpireAt'] != null
            ? DateTime.parse(json['holdExpireAt'])
            : null,
        customerName: json['customerName'],
        customerPhone: json['customerPhone'],
        depositAmount: (json['depositAmount'] as num?)?.toDouble(),
        guestCount: json['guestCount'] ?? 2,
        notes: json['notes'],
        holdRemainingSeconds: json['holdRemainingSeconds'] ?? 0,
        property: json['property'],
        sale: json['sale'],
        cancelledAt: json['cancelledAt'] != null
            ? DateTime.tryParse(json['cancelledAt'])
            : null,
        cancelledByUserId: json['cancelledByUserId'],
        cancelledByRole: json['cancelledByRole'] as int?,
        cancelledReason: json['cancelledReason'],
      );

  int get nights => checkoutDate.difference(checkinDate).inDays;

  String get propertyName => property?['name'] ?? 'N/A';

  String get saleName => sale?['name'] ?? 'N/A';

  String? get cancelledByRoleLabel {
    switch (cancelledByRole) {
      case 0:
        return 'Admin';
      case 1:
        return 'Chủ homestay';
      case 2:
        return 'Nhân viên';
      case 3:
        return 'Khách';
      default:
        return cancelledByRole == null ? 'Hệ thống' : null;
    }
  }
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
        status: BookingStatusExtension.fromInt(json['status'] ?? 0),
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
