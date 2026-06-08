import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../models/cccd_upload.dart';
import '../models/ocr_result.dart';
import '../models/payment_history_item.dart';
import '../models/payment_quote.dart';
import '../models/payment_session.dart';
import '../models/plan.dart';
import '../models/selfie_upload.dart';
import '../models/verify_enums.dart';

/// Kết quả submit hồ sơ chờ admin duyệt.
class SubmissionResult {
  final String submissionId;
  final VerifyStatus status;
  final DateTime submittedAt;

  const SubmissionResult({
    required this.submissionId,
    required this.status,
    required this.submittedAt,
  });
}

/// Kết quả check approval (poll mỗi 30s từ Screen 6).
class ApprovalResult {
  final VerifyStatus status;
  final DateTime? approvedAt;
  final DateTime? trialEndsAt;
  final DateTime? chargeStartsAt;
  final String? rejectReason;
  final List<RejectableItem> rejectedItems;

  const ApprovalResult({
    required this.status,
    this.approvedAt,
    this.trialEndsAt,
    this.chargeStartsAt,
    this.rejectReason,
    this.rejectedItems = const [],
  });
}

class RefundResult {
  final DateTime refundedAt;
  final int refundAmount;

  const RefundResult({required this.refundedAt, required this.refundAmount});
}

/// Snapshot trạng thái KYC hiện tại từ backend (`GET /kyc/status`).
class KycStatusSnapshot {
  final VerifyStatus status;
  final String? submissionId;
  final String? rejectReason;
  final List<RejectableItem> rejectedItems;
  final DateTime? approvedAt;
  final DateTime? trialEndsAt;

  /// Backend trả `uploads: { cccdFront: bool, cccdBack: bool, selfie: bool }`
  /// — `true` nghĩa là đã upload (nhưng có thể chưa có URL chi tiết).
  final bool hasCccdFront;
  final bool hasCccdBack;
  final bool hasSelfie;

  const KycStatusSnapshot({
    required this.status,
    this.submissionId,
    this.rejectReason,
    this.rejectedItems = const [],
    this.approvedAt,
    this.trialEndsAt,
    this.hasCccdFront = false,
    this.hasCccdBack = false,
    this.hasSelfie = false,
  });
}

abstract class VerifyRepository {
  Future<CCCDUpload> uploadCCCDFront(File image, {OCRResult? ocrResult});
  Future<CCCDUpload> uploadCCCDBack(File image, {OCRResult? ocrResult});
  Future<SelfieUpload> uploadSelfie(File image, {required String cccdFrontId});
  Future<KycStatusSnapshot> getKycStatus();

  Future<List<Plan>> fetchPlans();
  Future<PaymentQuote> fetchPaymentQuote({
    required String planId,
    required BillingCycle billingCycle,
    required int rooms,
  });
  Future<PaymentSession> initiatePayment({
    required String planId,
    required BillingCycle billingCycle,
    required PaymentMethod method,
    required int rooms,
    required int totalAmount,
  });
  Future<PaymentStatus> checkPaymentStatus(String sessionId);
  Future<void> cancelPayment(String sessionId);

  /// Session `pending` mới nhất — rehydrate QR/bankInfo sau reload app.
  Future<PaymentSession?> fetchActivePaymentSession();

  Future<SubmissionResult> submitForApproval();
  Future<ApprovalResult> checkApprovalStatus(String submissionId);
  Future<void> resubmit({required List<RejectableItem> items});
  Future<RefundResult> requestRefund(String submissionId);

  Future<PaymentHistoryPage> fetchPaymentHistory({
    int limit = 50,
    String? cursor,
  });

  Future<PaymentSession> renewSubscription({
    required PaymentMethod method,
  });
}

/// Lỗi nghiệp vụ KYC/payment — có thể kèm `code` từ BE (409 downgrade, frozen…).
class VerifyApiException implements Exception {
  final String message;
  final String? code;
  final DateTime? effectiveAt;
  final String? pendingPlanId;
  final PendingSessionSummary? pendingSession;

  /// Root body 409 `paymentPending` — BE trả flat (§ payment.service).
  final String? sessionId;
  final int? totalAmount;
  final DateTime? expiresAt;
  final DateTime? qrExpiresAt;

  const VerifyApiException(
    this.message, {
    this.code,
    this.effectiveAt,
    this.pendingPlanId,
    this.pendingSession,
    this.sessionId,
    this.totalAmount,
    this.expiresAt,
    this.qrExpiresAt,
  });

  factory VerifyApiException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      PendingSessionSummary? pendingSession;
      final pendingRaw = map['pendingSession'];
      if (pendingRaw is Map<String, dynamic>) {
        pendingSession = PendingSessionSummary.fromJson(pendingRaw);
      } else if (map['code'] == 'paymentPending') {
        final sessionId = map['sessionId'] as String?;
        final expiresRaw = map['expiresAt'] as String?;
        if (sessionId != null &&
            sessionId.isNotEmpty &&
            expiresRaw != null &&
            expiresRaw.isNotEmpty) {
          pendingSession = PendingSessionSummary(
            sessionId: sessionId,
            totalAmount: (map['totalAmount'] as num?)?.toInt() ?? 0,
            planId: map['planId'] as String?,
            expiresAt: DateTime.parse(expiresRaw),
            method: PaymentMethod.bankTransfer,
          );
        }
      }
      return VerifyApiException(
        map['message']?.toString() ?? parseDioError(e),
        code: map['code'] as String?,
        effectiveAt: _parseApiDate(map['effectiveAt']),
        pendingPlanId: map['pendingPlanId'] as String?,
        pendingSession: pendingSession,
        sessionId: map['sessionId'] as String?,
        totalAmount: (map['totalAmount'] as num?)?.toInt(),
        expiresAt: _parseApiDate(map['expiresAt']),
        qrExpiresAt: _parseApiDate(map['qrExpiresAt']),
      );
    }
    if (status == 404) {
      return const VerifyApiException(
        'Chức năng báo giá chưa có trên máy chủ.',
        code: 'quoteNotFound',
      );
    }
    return VerifyApiException(parseDioError(e));
  }

  bool get isDowngradeScheduled => code == 'downgradeScheduled';
  bool get isSubscriptionFrozen => code == 'subscriptionFrozen';
  bool get isNoActiveSubscription => code == 'noActiveSubscription';
  bool get isAmountMismatch => code == 'amountMismatch';
  bool get isPaymentPending => code == 'paymentPending';
  bool get isKycNotApproved => code == 'payment.kycNotApproved';

  /// Message hiển thị cho user — ưu tiên tiếng Việt.
  String get vietnameseMessage {
    switch (code) {
      case 'amountMismatch':
        return 'Số tiền không khớp với máy chủ. Vui lòng tải lại báo giá '
            'và thử lại.';
      case 'noActiveSubscription':
        return 'Bạn chưa có gói subscription đang hoạt động để gia hạn '
            'qua API gia hạn. Nếu đang dùng trial, app sẽ tự chuyển sang '
            'thanh toán gói hiện tại.';
      case 'subscriptionFrozen':
        return 'Tài khoản đang bị đóng băng. Vui lòng liên hệ hỗ trợ.';
      case 'downgradeScheduled':
        if (effectiveAt != null) {
          return 'Đã đặt lịch hạ gói. Gói mới sẽ áp dụng từ ngày '
              '${effectiveAt!.day.toString().padLeft(2, '0')}/'
              '${effectiveAt!.month.toString().padLeft(2, '0')}/'
              '${effectiveAt!.year}.';
        }
        return 'Đã đặt lịch hạ gói. Gói mới sẽ áp dụng từ kỳ tiếp theo.';
      case 'planNotFound':
        return 'Gói không tồn tại hoặc đã ngừng bán.';
      case 'payment.kycNotApproved':
        return 'Cần xác minh tài khoản trước khi thanh toán.';
    }

    final lower = message.toLowerCase();
    if (lower.contains('do not have an active') ||
        lower.contains('no active subscription') ||
        lower.contains('not have an active')) {
      return 'Chưa có gói đang hoạt động để gia hạn. '
          'Nếu bạn đang trong trial, vui lòng thử lại — hệ thống sẽ '
          'tạo phiên thanh toán gói hiện tại.';
    }

    return message;
  }

  @override
  String toString() => vietnameseMessage;
}

DateTime? _parseApiDate(dynamic raw) {
  if (raw == null || raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
