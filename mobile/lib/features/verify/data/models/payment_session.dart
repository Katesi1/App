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

/// An open payment session (VNPay / bank transfer / card).
class PaymentSession extends Equatable {
  final String sessionId;
  final PaymentMethod method;

  /// Total amount (VAT included) — VND.
  final int totalAmount;

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
    return PaymentSession(
      sessionId: (json['sessionId'] ?? json['session_id']) as String,
      method: method,
      totalAmount: (json['totalAmount'] ?? json['total_amount']) as int,
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
