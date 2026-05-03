import 'dart:io';

import '../models/cccd_upload.dart';
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

/// Abstract data source cho verify + subscription flow.
///
/// Implementation:
/// - [MockVerifyRepository]: dev/QA, không cần backend. Đang dùng làm mặc định.
/// - VerifyRepositoryImpl (chưa có): sẽ ghép Dio sau khi backend ready
///   (FPT.AI eKYC cho OCR + face match, VNPay sandbox cho payment).
abstract class VerifyRepository {
  // ── KYC ──
  Future<CCCDUpload> uploadCCCDFront(File image);
  Future<CCCDUpload> uploadCCCDBack(File image);
  Future<SelfieUpload> uploadSelfie(File image, {required String cccdFrontId});

  // ── Plans + Payment ──
  Future<List<Plan>> fetchPlans();
  Future<PaymentSession> initiatePayment({
    required String planId,
    required BillingCycle billingCycle,
    required PaymentMethod method,
    required int rooms,
    required int totalAmount,
  });
  Future<PaymentStatus> checkPaymentStatus(String sessionId);

  // ── Approval + Refund ──
  Future<SubmissionResult> submitForApproval();
  Future<ApprovalResult> checkApprovalStatus(String submissionId);
  Future<void> resubmit({required List<RejectableItem> items});
  Future<RefundResult> requestRefund(String submissionId);
}
