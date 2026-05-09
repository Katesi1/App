import 'package:equatable/equatable.dart';

import 'verify_enums.dart';

/// Một dòng trong lịch sử thanh toán (KYC initial + renew/extension).
///
/// Backend trả về từ `GET /payments/history`. Mỗi giao dịch lưu nguyên trạng
/// status hiện tại (paid/refunded/failed/expired) — KHÔNG xoá khi refund,
/// chỉ chuyển status để user tracking đầy đủ vòng đời.
class PaymentHistoryItem extends Equatable {
  final String id;

  /// Loại giao dịch:
  /// - `subscription` = thanh toán đăng ký lần đầu (sau KYC)
  /// - `renew` = gia hạn theo cycle hiện tại
  /// - `upgrade` = đổi sang plan cao hơn (charge prorate)
  /// - `refund` = giao dịch hoàn tiền (số âm)
  final PaymentHistoryKind kind;

  /// Hiển thị "Mini · Tháng" / "Standard · Năm" — backend trả sẵn.
  final String planLabel;

  /// Chu kỳ tính phí.
  final BillingCycle cycle;

  /// Số tiền (VND). Refund có thể là số dương — phân biệt qua `kind`.
  final int amount;

  final PaymentMethod method;
  final PaymentStatus status;

  /// Khi giao dịch được khởi tạo (POST /payments/initiate).
  final DateTime createdAt;

  /// Khi giao dịch hoàn tất (paid hoặc failed). Null nếu vẫn pending.
  final DateTime? settledAt;

  /// Mã giao dịch ngân hàng / VNPay reference (nullable).
  final String? referenceCode;

  /// Số hoá đơn (nếu có invoice riêng).
  final String? invoiceNumber;

  const PaymentHistoryItem({
    required this.id,
    required this.kind,
    required this.planLabel,
    required this.cycle,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
    this.settledAt,
    this.referenceCode,
    this.invoiceNumber,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      id: json['id'] as String,
      kind: _kindFromApi(json['kind'] as String? ?? 'subscription'),
      planLabel: (json['planLabel'] ?? json['plan_label'] ?? '') as String,
      cycle: (json['cycle'] as String? ?? 'monthly') == 'yearly'
          ? BillingCycle.yearly
          : BillingCycle.monthly,
      amount: (json['amount'] as num).toInt(),
      method: _methodFromString(json['method'] as String),
      status: _statusFromString(json['status'] as String),
      createdAt: DateTime.parse(
        (json['createdAt'] ?? json['created_at']) as String,
      ),
      settledAt: _parseDate(json['settledAt'] ?? json['settled_at']),
      referenceCode:
          json['referenceCode'] as String? ?? json['reference_code'] as String?,
      invoiceNumber:
          json['invoiceNumber'] as String? ?? json['invoice_number'] as String?,
    );
  }

  bool get isRefund => kind == PaymentHistoryKind.refund;

  @override
  List<Object?> get props => [
        id,
        kind,
        planLabel,
        cycle,
        amount,
        method,
        status,
        createdAt,
        settledAt,
        referenceCode,
        invoiceNumber,
      ];
}

enum PaymentHistoryKind { subscription, renew, upgrade, refund }

extension PaymentHistoryKindX on PaymentHistoryKind {
  String get label => switch (this) {
        PaymentHistoryKind.subscription => 'Đăng ký lần đầu',
        PaymentHistoryKind.renew => 'Gia hạn',
        PaymentHistoryKind.upgrade => 'Nâng cấp gói',
        PaymentHistoryKind.refund => 'Hoàn tiền',
      };
}

PaymentHistoryKind _kindFromApi(String raw) {
  switch (raw.toLowerCase()) {
    case 'renew':
    case 'renewal':
      return PaymentHistoryKind.renew;
    case 'upgrade':
      return PaymentHistoryKind.upgrade;
    case 'refund':
      return PaymentHistoryKind.refund;
    case 'subscription':
    default:
      return PaymentHistoryKind.subscription;
  }
}

PaymentMethod _methodFromString(String raw) {
  switch (raw.toLowerCase()) {
    case 'vnpay_qr':
    case 'vnpayqr':
      return PaymentMethod.vnpayQR;
    case 'card':
      return PaymentMethod.card;
    case 'bank_transfer':
    case 'banktransfer':
    default:
      return PaymentMethod.bankTransfer;
  }
}

PaymentStatus _statusFromString(String raw) {
  switch (raw.toLowerCase()) {
    case 'paid':
      return PaymentStatus.paid;
    case 'failed':
      return PaymentStatus.failed;
    case 'expired':
      return PaymentStatus.expired;
    case 'refunded':
      return PaymentStatus.refunded;
    case 'pending':
    default:
      return PaymentStatus.pending;
  }
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null || raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
