import 'package:equatable/equatable.dart';

import 'verify_enums.dart';

/// A row in the payment history (initial KYC + renew/extension).
///
/// Returned by `GET /payments/history`. Each transaction keeps its current
/// status (paid/refunded/failed/expired) — refunds do NOT delete the row, only
/// transition status, so the user can track the full lifecycle.
class PaymentHistoryItem extends Equatable {
  final String id;

  /// Transaction type:
  /// - `subscription` = initial subscription payment (post-KYC)
  /// - `renew` = renewal on the current cycle
  /// - `upgrade` = switch to a higher plan (prorated charge)
  /// - `refund` = refund transaction (negative)
  final PaymentHistoryKind kind;

  /// Display label like "Mini · Monthly" / "Standard · Yearly" — backend provides.
  final String planLabel;

  /// Billing cycle.
  final BillingCycle cycle;

  /// Amount (VND). Refunds may be positive — distinguish via `kind`.
  final int amount;

  final PaymentMethod method;
  final PaymentStatus status;

  /// When the transaction was created (POST /payments/initiate).
  final DateTime createdAt;

  /// When the transaction settled (paid or failed). Null if still pending.
  final DateTime? settledAt;

  /// Bank/VNPay reference code (nullable).
  final String? referenceCode;

  /// Invoice number (if a separate invoice is issued).
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

/// One page of history + cursor for the next fetch. Matches the response shape
/// `{ data: [...], meta: { nextCursor, limit } }` from backend (see
/// `api-payments-frontend-spec.md` §5).
class PaymentHistoryPage extends Equatable {
  final List<PaymentHistoryItem> items;

  /// Pass via query `?cursor=...` to fetch the next page. `null` ⇒ no more data.
  final String? nextCursor;

  final int limit;

  const PaymentHistoryPage({
    required this.items,
    this.nextCursor,
    this.limit = 50,
  });

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  factory PaymentHistoryPage.fromResponse(Map<String, dynamic> response) {
    final list =
        (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final meta = response['meta'] as Map<String, dynamic>?;
    return PaymentHistoryPage(
      items: list.map(PaymentHistoryItem.fromJson).toList(),
      nextCursor: meta?['nextCursor'] as String?,
      limit: (meta?['limit'] as num?)?.toInt() ?? 50,
    );
  }

  @override
  List<Object?> get props => [items, nextCursor, limit];
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
