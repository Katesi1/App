import 'package:equatable/equatable.dart';

import 'verify_enums.dart';

/// Bank transfer info (backend returns it as an object).
class BankInfo extends Equatable {
  final String bankName;
  final String accountNumber;
  final String accountName;

  /// Transfer memo (e.g. "KYC ABC123DE").
  final String content;

  /// VietQR payload (EMVCo standard, FE renders via `QrImageView`).
  /// Backend either generates it from the VietQR.io API or builds the EMV
  /// string from account + amount + content. Nullable for backwards compat
  /// when the backend hasn't wired it yet.
  final String? vietQrPayload;

  /// NAPAS-standard BIN (Bank Identification Number), e.g. `970436` for VCB.
  /// Used to load the bank logo from vietqr.io (see `bankLogoUrl`). Optional —
  /// new backend (post 2026-05-09) returns it; older versions return null.
  final String? bankBin;

  const BankInfo({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.content,
    this.vietQrPayload,
    this.bankBin,
  });

  factory BankInfo.fromJson(Map<String, dynamic> json) => BankInfo(
        bankName: (json['bankName'] ?? json['bank_name'] ?? '') as String,
        accountNumber:
            (json['accountNumber'] ?? json['account_number'] ?? '') as String,
        accountName:
            (json['accountName'] ?? json['account_name'] ?? '') as String,
        content: (json['content'] ?? '') as String,
        vietQrPayload:
            (json['vietQrPayload'] ?? json['viet_qr_payload']) as String?,
        bankBin: (json['bankBin'] ?? json['bank_bin']) as String?,
      );

  Map<String, dynamic> toJson() => {
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountName': accountName,
        'content': content,
        if (vietQrPayload != null) 'vietQrPayload': vietQrPayload,
        if (bankBin != null) 'bankBin': bankBin,
      };

  /// 4-line display format for the "Bank transfer" dialog.
  String get displayText => 'Ngân hàng: $bankName\n'
      'STK: $accountNumber\n'
      'Tên: $accountName\n'
      'Nội dung: $content';

  /// Bank logo URL from vietqr.io. Null if backend doesn't return `bankBin`.
  String? get bankLogoUrl => bankBin == null || bankBin!.isEmpty
      ? null
      : 'https://api.vietqr.io/img/$bankBin.png';

  /// img.vietqr.io quick-link QR image (server-rendered, encodes account +
  /// amount + memo). Used as a fallback when the backend doesn't return a raw
  /// EMVCo [vietQrPayload]. Returns null if we lack the BIN or account number
  /// needed to build it. All values come from the backend `bankInfo` — nothing
  /// is hardcoded.
  String? vietQrImageUrl(int amount) {
    if (bankBin == null || bankBin!.isEmpty || accountNumber.isEmpty) {
      return null;
    }
    final params = <String, String>{
      'amount': amount.toString(),
      'addInfo': content,
      if (accountName.isNotEmpty) 'accountName': accountName,
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return 'https://img.vietqr.io/image/$bankBin-$accountNumber-compact2.png?$query';
  }

  @override
  List<Object?> get props => [
        bankName,
        accountNumber,
        accountName,
        content,
        vietQrPayload,
        bankBin,
      ];
}

/// Chi tiết giá BE trả (quote + initiate/renew). FE đọc thẳng, KHÔNG tự tính.
class PaymentBreakdown extends Equatable {
  final int listPrice;
  final int creditApplied; // > 0 chỉ khi upgrade
  final int vat;

  /// Chỉ có khi upgrade (prorate). null nếu không phải upgrade.
  final int? remainingDays;
  final int? totalDays;
  final String? currentPlanId;

  /// Số tháng kỳ được gia hạn (renew/subscription: 1 hoặc 12; upgrade: null).
  final int? periodExtensionMonths;

  const PaymentBreakdown({
    required this.listPrice,
    required this.creditApplied,
    required this.vat,
    this.remainingDays,
    this.totalDays,
    this.currentPlanId,
    this.periodExtensionMonths,
  });

  factory PaymentBreakdown.fromJson(Map<String, dynamic> json) {
    final pe = json['periodExtension'];
    return PaymentBreakdown(
      listPrice: (json['listPrice'] as num?)?.toInt() ?? 0,
      creditApplied: (json['creditApplied'] as num?)?.toInt() ?? 0,
      vat: (json['vat'] as num?)?.toInt() ?? 0,
      remainingDays: (json['remainingDays'] as num?)?.toInt(),
      totalDays: (json['totalDays'] as num?)?.toInt(),
      currentPlanId: json['currentPlanId'] as String?,
      periodExtensionMonths: pe is Map ? (pe['months'] as num?)?.toInt() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'listPrice': listPrice,
        'creditApplied': creditApplied,
        'vat': vat,
        if (remainingDays != null) 'remainingDays': remainingDays,
        if (totalDays != null) 'totalDays': totalDays,
        if (currentPlanId != null) 'currentPlanId': currentPlanId,
        if (periodExtensionMonths != null)
          'periodExtension': {'months': periodExtensionMonths},
      };

  @override
  List<Object?> get props => [
        listPrice,
        creditApplied,
        vat,
        remainingDays,
        totalDays,
        currentPlanId,
        periodExtensionMonths,
      ];
}

/// Báo giá (`POST /payments/quote`) — FE gọi trước khi mở màn thanh toán để biết
/// số tiền + loại giao dịch. Không tạo session.
class PaymentQuote extends Equatable {
  final TransactionKind? kind;
  final String planId;
  final String cycle;
  final int rooms;
  final int totalAmount;
  final PaymentBreakdown breakdown;

  const PaymentQuote({
    required this.kind,
    required this.planId,
    required this.cycle,
    required this.rooms,
    required this.totalAmount,
    required this.breakdown,
  });

  factory PaymentQuote.fromJson(Map<String, dynamic> json) => PaymentQuote(
        kind: transactionKindFromApi(json['kind'] as String?),
        planId: (json['planId'] ?? '') as String,
        cycle: (json['cycle'] ?? 'monthly') as String,
        rooms: (json['rooms'] as num?)?.toInt() ?? 0,
        totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
        breakdown: PaymentBreakdown.fromJson(
            (json['breakdown'] as Map<String, dynamic>?) ?? const {}),
      );

  @override
  List<Object?> get props =>
      [kind, planId, cycle, rooms, totalAmount, breakdown];
}

/// Thông tin phiên đang chờ (kèm trong 409 `paymentPending`). Đủ để hiển thị
/// + resume (qua `GET /payments/active`) hoặc huỷ (`POST /payments/:id/cancel`).
class PendingSessionInfo {
  final String sessionId;
  final TransactionKind? kind;
  final int totalAmount;
  final String? planId;
  final String? planLabel;
  final String? cycle;
  final String? method;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const PendingSessionInfo({
    required this.sessionId,
    this.kind,
    this.totalAmount = 0,
    this.planId,
    this.planLabel,
    this.cycle,
    this.method,
    this.createdAt,
    this.expiresAt,
  });

  factory PendingSessionInfo.fromJson(Map<String, dynamic> json) {
    DateTime? d(dynamic v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
    return PendingSessionInfo(
      sessionId: (json['sessionId'] ?? '') as String,
      kind: transactionKindFromApi(json['kind'] as String?),
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      planId: json['planId'] as String?,
      planLabel: json['planLabel'] as String?,
      cycle: json['cycle'] as String?,
      method: json['method'] as String?,
      createdAt: d(json['createdAt']),
      expiresAt: d(json['expiresAt']),
    );
  }
}

/// An open payment session (VNPay / bank transfer / card).
class PaymentSession extends Equatable {
  final String sessionId;
  final PaymentMethod method;

  /// Total amount (VAT included) — VND.
  final int totalAmount;

  /// Loại giao dịch BE tự branch (subscription | renew | upgrade | downgrade).
  final TransactionKind? kind;

  /// Plan + cycle BE chốt cho phiên này (có thể khác draft local khi upgrade).
  final String? planId;
  final String? cycle;

  /// Chi tiết giá BE trả về (FE render trong order summary).
  final PaymentBreakdown? breakdown;

  /// VNPay QR payload — raw EMVCo string (FE renders via `QrImageView`).
  /// Backend returns it after calling the VNPay createQR API.
  ///
  /// If backend returns base64 PNG instead of EMV string, use [qrImageBase64].
  final String? qrCode;

  /// Fallback: base64 PNG QR image (`data:image/png;base64,...` or raw base64).
  /// Used when backend can't easily emit EMV strings and renders the QR image
  /// itself.
  final String? qrImageBase64;

  /// Bank transfer info (only for bank transfer method).
  final BankInfo? bankInfo;

  /// Redirect URL — VNPay Gateway flow (opens WebView/browser to enter
  /// ATM/international card).
  final String? redirectUrl;

  /// Deeplink to open a banking app on the same device (e.g. `vnpay://...`).
  /// After the user pays, the banking app calls back via deeplink.
  final String? payUrl;

  final DateTime expiresAt;

  const PaymentSession({
    required this.sessionId,
    required this.method,
    required this.totalAmount,
    this.kind,
    this.planId,
    this.cycle,
    this.breakdown,
    this.qrCode,
    this.qrImageBase64,
    this.bankInfo,
    this.redirectUrl,
    this.payUrl,
    required this.expiresAt,
  });

  factory PaymentSession.fromJson(Map<String, dynamic> json) {
    final methodRaw = (json['method'] as String).toLowerCase();
    final method = _methodFromApi(methodRaw);
    final bankRaw = json['bankInfo'] ?? json['bank_info'];
    final breakdownRaw = json['breakdown'];
    return PaymentSession(
      sessionId: (json['sessionId'] ?? json['session_id']) as String,
      method: method,
      totalAmount: (json['totalAmount'] ?? json['total_amount']) as int,
      kind: transactionKindFromApi(json['kind'] as String?),
      planId: (json['planId'] ?? json['plan_id']) as String?,
      cycle: json['cycle'] as String?,
      breakdown: breakdownRaw is Map<String, dynamic>
          ? PaymentBreakdown.fromJson(breakdownRaw)
          : null,
      qrCode: (json['qrCode'] ?? json['qr_code']) as String?,
      qrImageBase64:
          (json['qrImageBase64'] ?? json['qr_image_base64']) as String?,
      bankInfo:
          bankRaw is Map<String, dynamic> ? BankInfo.fromJson(bankRaw) : null,
      redirectUrl: (json['redirectUrl'] ?? json['redirect_url']) as String?,
      payUrl: (json['payUrl'] ?? json['pay_url']) as String?,
      expiresAt: DateTime.parse(
        (json['expiresAt'] ?? json['expires_at']) as String,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'method': method.toApiString(),
        'totalAmount': totalAmount,
        if (kind != null) 'kind': kind!.name,
        if (planId != null) 'planId': planId,
        if (cycle != null) 'cycle': cycle,
        if (breakdown != null) 'breakdown': breakdown!.toJson(),
        'qrCode': qrCode,
        'qrImageBase64': qrImageBase64,
        'bankInfo': bankInfo?.toJson(),
        'redirectUrl': redirectUrl,
        'payUrl': payUrl,
        'expiresAt': expiresAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        sessionId,
        method,
        totalAmount,
        kind,
        planId,
        cycle,
        breakdown,
        qrCode,
        qrImageBase64,
        bankInfo,
        redirectUrl,
        payUrl,
        expiresAt,
      ];
}

/// Backend uses `vnpay_qr|bank_transfer|card`; frontend enum uses camelCase.
PaymentMethod _methodFromApi(String raw) {
  switch (raw) {
    case 'vnpay_qr':
    case 'vnpayqr':
      return PaymentMethod.vnpayQR;
    case 'bank_transfer':
    case 'banktransfer':
      return PaymentMethod.bankTransfer;
    case 'card':
      return PaymentMethod.card;
    default:
      // Fallback by enum.name
      return PaymentMethod.values.firstWhere(
        (m) => m.name.toLowerCase() == raw,
        orElse: () => PaymentMethod.bankTransfer,
      );
  }
}

extension PaymentMethodApi on PaymentMethod {
  /// Convert to backend format (snake_case) for POST /payments/initiate.
  String toApiString() {
    switch (this) {
      case PaymentMethod.vnpayQR:
        return 'vnpay_qr';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.card:
        return 'card';
    }
  }
}

/// Convert backend status string → frontend enum.
PaymentStatus paymentStatusFromApi(String raw) {
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

/// Convert backend KYC status string → frontend enum.
VerifyStatus verifyStatusFromApi(String raw) {
  switch (raw) {
    case 'kycSubmitted':
    case 'kyc_submitted':
      return VerifyStatus.kycSubmitted;
    case 'paymentPending':
    case 'payment_pending':
      return VerifyStatus.paymentPending;
    case 'awaitingApproval':
    case 'awaiting_approval':
      return VerifyStatus.awaitingApproval;
    case 'approved':
      return VerifyStatus.approved;
    case 'rejected':
      return VerifyStatus.rejected;
    case 'refunded':
      return VerifyStatus.refunded;
    case 'draft':
    default:
      return VerifyStatus.draft;
  }
}
