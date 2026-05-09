import 'package:equatable/equatable.dart';

import 'verify_enums.dart';

/// Thông tin chuyển khoản ngân hàng (backend trả về dạng object).
class BankInfo extends Equatable {
  final String bankName;
  final String accountNumber;
  final String accountName;

  /// Nội dung chuyển khoản (vd "KYC ABC123DE").
  final String content;

  /// VietQR payload (chuẩn EMVCo, FE render bằng `QrImageView`).
  /// Backend sinh từ VietQR.io API hoặc tự build EMV string từ STK + amount + content.
  /// Nullable để backwards-compat nếu backend chưa wire.
  final String? vietQrPayload;

  const BankInfo({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.content,
    this.vietQrPayload,
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
      );

  Map<String, dynamic> toJson() => {
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountName': accountName,
        'content': content,
        if (vietQrPayload != null) 'vietQrPayload': vietQrPayload,
      };

  /// Format hiển thị 4 dòng cho dialog "Chuyển khoản".
  String get displayText => 'Ngân hàng: $bankName\n'
      'STK: $accountNumber\n'
      'Tên: $accountName\n'
      'Nội dung: $content';

  @override
  List<Object?> get props =>
      [bankName, accountNumber, accountName, content, vietQrPayload];
}

/// Một phiên thanh toán đang mở (VNPay / bank transfer / card).
class PaymentSession extends Equatable {
  final String sessionId;
  final PaymentMethod method;

  /// Tổng tiền (đã bao gồm VAT) — VND.
  final int totalAmount;

  /// QR payload cho VNPay QR — định dạng EMVCo string raw (FE tự render bằng
  /// `QrImageView`). Backend trả về sau khi gọi VNPay createQR API.
  ///
  /// Nếu backend trả base64 PNG thay vì EMV string, dùng [qrImageBase64].
  final String? qrCode;

  /// Fallback: ảnh QR base64 PNG (`data:image/png;base64,...` hoặc raw base64).
  /// Dùng khi backend không tiện sinh EMV string mà render QR rồi gửi ảnh.
  final String? qrImageBase64;

  /// Thông tin chuyển khoản (chỉ áp dụng bank transfer).
  final BankInfo? bankInfo;

  /// Redirect URL — VNPay Gateway flow (mở WebView/browser để nhập thẻ ATM/quốc tế).
  final String? redirectUrl;

  /// Deeplink để mở app banking trên cùng device (vd `vnpay://...`).
  /// Sau khi user thanh toán xong, app banking sẽ callback về app qua deeplink.
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

/// Backend dùng `vnpay_qr|bank_transfer|card`, frontend enum dùng camelCase.
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
      // Fallback theo enum.name
      return PaymentMethod.values.firstWhere(
        (m) => m.name.toLowerCase() == raw,
        orElse: () => PaymentMethod.bankTransfer,
      );
  }
}

extension PaymentMethodApi on PaymentMethod {
  /// Convert sang format backend (snake_case) khi gửi POST /payments/initiate.
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

/// Convert backend status string → enum frontend.
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

/// Convert backend KYC status string → enum frontend.
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
