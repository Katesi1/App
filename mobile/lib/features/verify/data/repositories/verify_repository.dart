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

/// Abstract data source cho verify + subscription flow.
///
/// Implementation:
/// - [MockVerifyRepository]: dev/QA, không cần backend.
/// - `VerifyRepositoryImpl`: gọi real backend (xem
///   `verify_repository_impl.dart`).
abstract class VerifyRepository {
  // ── KYC ──
  Future<CCCDUpload> uploadCCCDFront(File image);
  Future<CCCDUpload> uploadCCCDBack(File image);
  Future<SelfieUpload> uploadSelfie(File image, {required String cccdFrontId});

  /// Lấy trạng thái KYC hiện tại của user (resume sau khi mở app lại).
  Future<KycStatusSnapshot> getKycStatus();

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
