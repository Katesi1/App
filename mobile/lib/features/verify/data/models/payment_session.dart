import 'package:equatable/equatable.dart';

import 'verify_enums.dart';

/// Một phiên thanh toán đang mở (VNPay / bank transfer / card).
class PaymentSession extends Equatable {
  final String sessionId;
  final PaymentMethod method;

  /// Tổng tiền (đã bao gồm VAT) — VND.
  final int totalAmount;

  /// QR code base64 string (chỉ áp dụng VNPay).
  final String? qrCode;

  /// STK + nội dung CK (bank transfer).
  final String? bankInfo;

  /// Redirect URL (VNPay / card form).
  final String? redirectUrl;

  final DateTime expiresAt;

  const PaymentSession({
    required this.sessionId,
    required this.method,
    required this.totalAmount,
    this.qrCode,
    this.bankInfo,
    this.redirectUrl,
    required this.expiresAt,
  });

  factory PaymentSession.fromJson(Map<String, dynamic> json) => PaymentSession(
        sessionId: (json['sessionId'] ?? json['session_id']) as String,
        method: PaymentMethod.values
            .firstWhere((m) => m.name == json['method'] as String),
        totalAmount: (json['totalAmount'] ?? json['total_amount']) as int,
        qrCode: (json['qrCode'] ?? json['qr_code']) as String?,
        bankInfo: (json['bankInfo'] ?? json['bank_info']) as String?,
        redirectUrl: (json['redirectUrl'] ?? json['redirect_url']) as String?,
        expiresAt: DateTime.parse(
          (json['expiresAt'] ?? json['expires_at']) as String,
        ),
      );

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'method': method.name,
        'totalAmount': totalAmount,
        'qrCode': qrCode,
        'bankInfo': bankInfo,
        'redirectUrl': redirectUrl,
        'expiresAt': expiresAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [sessionId, method, totalAmount, qrCode, bankInfo, redirectUrl, expiresAt];
}
