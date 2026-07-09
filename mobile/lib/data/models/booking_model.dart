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
  // Payment (set qua PATCH /bookings/:id/paid) — null cho tới khi ghi nhận tiền.
  final double? totalAmount;
  final double? paidAmount;
  // `= max(0, totalAmount − paidAmount)`; null khi totalAmount = null. BE trả
  // sẵn — FE KHÔNG tự trừ (§5.3).
  final double? remainingAmount;
  final DateTime? paidAt;
  // Chi tiết tính giá từng đêm để hiển thị minh bạch. null khi chưa cấu hình giá.
  final BookingPriceBreakdown? priceBreakdown;
  // URL ảnh bill CK cọc khách gửi từ web (§5.6) — owner đối chiếu trước khi
  // ghi nhận cọc. null khi khách chưa gửi.
  final String? depositProofUrl;
  // Thời điểm owner xác nhận khách nhận phòng qua PATCH /checkin (§5.5).
  final DateTime? checkedInAt;
  // Thời điểm booking hoàn tất (owner check-in hoặc cron auto-complete).
  final DateTime? completedAt;
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
    this.totalAmount,
    this.paidAmount,
    this.remainingAmount,
    this.paidAt,
    this.priceBreakdown,
    this.depositProofUrl,
    this.checkedInAt,
    this.completedAt,
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
        totalAmount: (json['totalAmount'] as num?)?.toDouble(),
        paidAmount: (json['paidAmount'] as num?)?.toDouble(),
        remainingAmount: (json['remainingAmount'] as num?)?.toDouble(),
        paidAt:
            json['paidAt'] != null ? DateTime.tryParse(json['paidAt']) : null,
        priceBreakdown: json['priceBreakdown'] != null
            ? BookingPriceBreakdown.fromJson(
                json['priceBreakdown'] as Map<String, dynamic>)
            : null,
        depositProofUrl: json['depositProofUrl'],
        checkedInAt: json['checkedInAt'] != null
            ? DateTime.tryParse(json['checkedInAt'])
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'])
            : null,
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

  /// Đã ghi nhận thanh toán (cọc hoặc đủ tiền) qua PATCH /bookings/:id/paid.
  bool get isPaid => paidAt != null;

  /// Property chưa cấu hình giá → BE trả totalAmount = null (§5.3). UI hiện
  /// "Chưa chốt giá", KHÔNG hardcode 0 ₫.
  bool get hasPrice => totalAmount != null;

  /// Booking đang CONFIRMED và chưa check-in → owner có thể xác nhận nhận
  /// phòng + thu nốt (PATCH /bookings/:id/checkin, §5.5).
  bool get canCheckin =>
      status == BookingStatus.confirmed && checkedInAt == null;

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

/// Chi tiết tính giá booking (§5.3 `priceBreakdown`) — hiển thị minh bạch
/// từng đêm + phụ thu để owner đối chiếu tổng tiền.
class BookingPriceBreakdown {
  final int nights;
  final List<PriceLineItem> lineItems;
  final int extraAdults;
  final int extraChildren;
  final double surchargePerNight;
  final double surchargeTotal;
  final double roomTotal;
  final double total;

  const BookingPriceBreakdown({
    required this.nights,
    required this.lineItems,
    this.extraAdults = 0,
    this.extraChildren = 0,
    this.surchargePerNight = 0,
    this.surchargeTotal = 0,
    this.roomTotal = 0,
    this.total = 0,
  });

  factory BookingPriceBreakdown.fromJson(Map<String, dynamic> json) =>
      BookingPriceBreakdown(
        nights: json['nights'] ?? 0,
        lineItems: (json['lineItems'] as List?)
                ?.map((e) => PriceLineItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        extraAdults: json['extraAdults'] ?? 0,
        extraChildren: json['extraChildren'] ?? 0,
        surchargePerNight: (json['surchargePerNight'] as num?)?.toDouble() ?? 0,
        surchargeTotal: (json['surchargeTotal'] as num?)?.toDouble() ?? 0,
        roomTotal: (json['roomTotal'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
      );
}

/// Một dòng giá theo đêm trong `priceBreakdown.lineItems`.
/// [type]: `weekday | weekend | holiday`.
class PriceLineItem {
  final String date;
  final String type;
  final double amount;

  const PriceLineItem({
    required this.date,
    required this.type,
    required this.amount,
  });

  factory PriceLineItem.fromJson(Map<String, dynamic> json) => PriceLineItem(
        date: json['date'] ?? '',
        type: json['type'] ?? 'weekday',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );
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
