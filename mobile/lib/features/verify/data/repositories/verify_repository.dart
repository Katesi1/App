import 'dart:io';

import '../models/cccd_upload.dart';
import '../models/ocr_result.dart';
import '../models/payment_history_item.dart';
import '../models/payment_session.dart';
import '../models/plan.dart';
import '../models/selfie_upload.dart';
import '../models/verify_enums.dart';

/// Result of submitting an application for admin review.
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

/// Result of an approval poll (called every 30s from Screen 6).
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

/// Snapshot of the current KYC state from backend (`GET /kyc/status`).
class KycStatusSnapshot {
  final VerifyStatus status;
  final String? submissionId;
  final String? rejectReason;
  final List<RejectableItem> rejectedItems;
  final DateTime? approvedAt;
  final DateTime? trialEndsAt;

  /// Backend returns `uploads: { cccdFront: bool, cccdBack: bool, selfie: bool }`
  /// — `true` means uploaded (but the detailed URL may not be available yet).
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
  Future<PaymentSession> initiatePayment({
    required String planId,
    required BillingCycle billingCycle,
    required PaymentMethod method,
    required int rooms,
    required int totalAmount,
  });
  Future<PaymentStatus> checkPaymentStatus(String sessionId);

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
