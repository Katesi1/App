import 'dart:io';
import 'dart:math';

import '../models/cccd_upload.dart';
import '../models/ocr_result.dart';
import '../models/payment_session.dart';
import '../models/plan.dart';
import '../models/selfie_upload.dart';
import '../models/verify_enums.dart';
import 'verify_repository.dart';

/// Mock implementation — không gọi backend thật.
///
/// Mục đích: dev có thể build full flow mà không cần backend ready.
/// Tất cả delay đều ngắn (200-2000ms) để feedback nhanh.
///
/// Tunable knobs (constructor) cho QA test edge case:
/// - [forceFaceMismatch]: ép selfie luôn fail face match (test 3-strike lock)
/// - [forceLowOcrConfidence]: ép OCR confidence thấp (test warning)
/// - [paymentSucceedsAfter]: số poll trước khi payment chuyển paid
/// - [approvalAction]: 'approve' | 'reject' | 'pending' — quyết định kết quả admin
class MockVerifyRepository implements VerifyRepository {
  final bool forceFaceMismatch;
  final bool forceLowOcrConfidence;
  final int paymentSucceedsAfter;
  final String approvalAction;

  /// Số lần đã check payment status (để mock paid sau N poll).
  int _paymentCheckCount = 0;

  /// Số lần đã check approval status.
  int _approvalCheckCount = 0;

  MockVerifyRepository({
    this.forceFaceMismatch = false,
    this.forceLowOcrConfidence = false,
    this.paymentSucceedsAfter = 1,
    this.approvalAction = 'approve',
  });

  @override
  Future<CCCDUpload> uploadCCCDFront(File image) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    return CCCDUpload(
      id: 'cccd_front_${_randomId()}',
      imageUrl: 'https://placehold.co/640x400/16252B/B5D4DA?text=CCCD+Front',
      ocrResult: const OCRResult(
        cccdNumber: '001192012345',
        fullName: 'NGUYỄN VĂN TUẤN',
        dob: '12/05/1992',
        address: 'Tổ 5, P. Hồng Hà, TP. Hạ Long, Quảng Ninh',
        gender: 'Nam',
        expiryDate: '12/05/2027',
      ),
      confidence: forceLowOcrConfidence ? 0.62 : 0.94,
      uploadedAt: DateTime.now(),
      localPath: image.path,
    );
  }

  @override
  Future<CCCDUpload> uploadCCCDBack(File image) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    return CCCDUpload(
      id: 'cccd_back_${_randomId()}',
      imageUrl: 'https://placehold.co/640x400/16252B/B5D4DA?text=CCCD+Back',
      confidence: forceLowOcrConfidence ? 0.65 : 0.91,
      uploadedAt: DateTime.now(),
      localPath: image.path,
    );
  }

  @override
  Future<SelfieUpload> uploadSelfie(File image,
      {required String cccdFrontId}) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return SelfieUpload(
      id: 'selfie_${_randomId()}',
      imageUrl: 'https://placehold.co/400x500/16252B/B5D4DA?text=Selfie',
      faceMatchScore: forceFaceMismatch ? 0.62 : 0.92,
      isValid: !forceFaceMismatch,
      uploadedAt: DateTime.now(),
      localPath: image.path,
    );
  }

  @override
  Future<List<Plan>> fetchPlans() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return kDefaultPlans;
  }

  @override
  Future<PaymentSession> initiatePayment({
    required String planId,
    required BillingCycle billingCycle,
    required PaymentMethod method,
    required int rooms,
    required int totalAmount,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _paymentCheckCount = 0; // reset
    return PaymentSession(
      sessionId: 'pay_${_randomId()}',
      method: method,
      totalAmount: totalAmount,
      qrCode: method == PaymentMethod.vnpayQR
          ? 'https://placehold.co/300x300/FFFFFF/16252B?text=VNPay+QR'
          : null,
      bankInfo: method == PaymentMethod.bankTransfer
          ? 'Vietcombank · 0123456789 · CTY HALONG24H · NĐ: VERIFY pay_${_randomId()}'
          : null,
      redirectUrl: method == PaymentMethod.card
          ? 'https://sandbox.vnpay.vn/checkout?session=pay_${_randomId()}'
          : null,
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
  }

  @override
  Future<PaymentStatus> checkPaymentStatus(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _paymentCheckCount++;
    if (_paymentCheckCount >= paymentSucceedsAfter) {
      return PaymentStatus.paid;
    }
    return PaymentStatus.pending;
  }

  @override
  Future<SubmissionResult> submitForApproval() async {
    await Future.delayed(const Duration(milliseconds: 600));
    _approvalCheckCount = 0;
    return SubmissionResult(
      submissionId: 'sub_${_randomId()}',
      status: VerifyStatus.awaitingApproval,
      submittedAt: DateTime.now(),
    );
  }

  @override
  Future<ApprovalResult> checkApprovalStatus(String submissionId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _approvalCheckCount++;

    // Mock: 2 lần đầu vẫn pending, lần 3 trả về kết quả final
    // (giúp QA test screen pending → approved/rejected transition).
    if (_approvalCheckCount < 3) {
      return const ApprovalResult(status: VerifyStatus.awaitingApproval);
    }

    if (approvalAction == 'reject') {
      return ApprovalResult(
        status: VerifyStatus.rejected,
        rejectReason:
            'Ảnh CCCD mặt trước bị mờ, không đọc được số CCCD ở góc dưới-trái. '
            'Vui lòng chụp lại ảnh rõ nét hơn, đảm bảo ánh sáng đủ và không bị bóng phản chiếu.',
        rejectedItems: const [RejectableItem.cccdFront],
      );
    }

    if (approvalAction == 'pending') {
      return const ApprovalResult(status: VerifyStatus.awaitingApproval);
    }

    // Default: approve
    final now = DateTime.now();
    return ApprovalResult(
      status: VerifyStatus.approved,
      approvedAt: now,
      trialEndsAt: now.add(const Duration(days: 7)),
      chargeStartsAt: now.add(const Duration(days: 7)),
    );
  }

  @override
  Future<void> resubmit({required List<RejectableItem> items}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _approvalCheckCount = 0; // reset polling
  }

  @override
  Future<RefundResult> requestRefund(String submissionId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return RefundResult(
      refundedAt: DateTime.now(),
      refundAmount: 23602000,
    );
  }

  String _randomId() =>
      Random().nextInt(999999).toString().padLeft(6, '0');
}
