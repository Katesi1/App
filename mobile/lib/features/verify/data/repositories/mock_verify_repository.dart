import 'dart:io';
import 'dart:math';

import '../models/cccd_upload.dart';
import '../models/ocr_result.dart';
import '../models/payment_history_item.dart';
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
  Future<CCCDUpload> uploadCCCDFront(File image, {OCRResult? ocrResult}) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    // Mock: ưu tiên `ocrResult` client gửi (giả lập backend lưu nguyên xi);
    // fallback hardcoded data khi gallery upload không có OCR.
    final ocr = ocrResult ??
        const OCRResult(
          cccdNumber: '001192012345',
          fullName: 'NGUYỄN VĂN TUẤN',
          dob: '12/05/1992',
          address: 'Tổ 5, P. Hồng Hà, TP. Hạ Long, Quảng Ninh',
          gender: 'Nam',
          expiryDate: '12/05/2027',
        );
    return CCCDUpload(
      id: 'cccd_front_${_randomId()}',
      imageUrl: 'https://placehold.co/640x400/16252B/B5D4DA?text=CCCD+Front',
      ocrResult: ocr,
      confidence: forceLowOcrConfidence ? 0.62 : 0.94,
      uploadedAt: DateTime.now(),
      localPath: image.path,
    );
  }

  @override
  Future<CCCDUpload> uploadCCCDBack(File image, {OCRResult? ocrResult}) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    return CCCDUpload(
      id: 'cccd_back_${_randomId()}',
      imageUrl: 'https://placehold.co/640x400/16252B/B5D4DA?text=CCCD+Back',
      ocrResult: ocrResult,
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
  Future<KycStatusSnapshot> getKycStatus() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const KycStatusSnapshot(status: VerifyStatus.draft);
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
    final sid = 'pay_${_randomId()}';
    final ckContent = 'HALONG24H ${sid.toUpperCase()}';
    return PaymentSession(
      sessionId: sid,
      method: method,
      totalAmount: totalAmount,
      // EMV-like fake payload — đủ để render QR test, không decode ra tiền thật
      qrCode: method == PaymentMethod.vnpayQR
          ? 'vnpay://halong24h.demo/pay?session=$sid&amount=$totalAmount'
          : null,
      bankInfo: method == PaymentMethod.bankTransfer
          ? BankInfo(
              bankName: 'Vietcombank',
              accountNumber: '0123456789',
              accountName: 'CTY HALONG24H',
              content: ckContent,
              // Fake VietQR payload — render được; thực tế là EMV string từ
              // VietQR.io/NAPAS với BIN ngân hàng thật.
              vietQrPayload:
                  'vietqr://demo?bank=VCB&account=0123456789&amount=$totalAmount&content=$ckContent',
            )
          : null,
      redirectUrl: method == PaymentMethod.card
          ? 'https://sandbox.vnpay.vn/checkout?session=$sid'
          : null,
      payUrl: method == PaymentMethod.vnpayQR
          ? 'https://sandbox.vnpay.vn/paymentv2/vpcpay.html?session=$sid'
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

  @override
  Future<List<PaymentHistoryItem>> fetchPaymentHistory() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    return [
      PaymentHistoryItem(
        id: 'pay_renew_001',
        kind: PaymentHistoryKind.renew,
        planLabel: 'Standard · Tháng',
        cycle: BillingCycle.monthly,
        amount: 6589000,
        method: PaymentMethod.vnpayQR,
        status: PaymentStatus.paid,
        createdAt: now.subtract(const Duration(days: 2)),
        settledAt: now.subtract(const Duration(days: 2, minutes: -3)),
        referenceCode: 'VNP-238910238',
        invoiceNumber: 'INV-2026-0042',
      ),
      PaymentHistoryItem(
        id: 'pay_renew_002',
        kind: PaymentHistoryKind.renew,
        planLabel: 'Standard · Tháng',
        cycle: BillingCycle.monthly,
        amount: 6589000,
        method: PaymentMethod.bankTransfer,
        status: PaymentStatus.paid,
        createdAt: now.subtract(const Duration(days: 33)),
        settledAt: now.subtract(const Duration(days: 33, hours: -1)),
        referenceCode: 'VCB-09872341',
        invoiceNumber: 'INV-2026-0029',
      ),
      PaymentHistoryItem(
        id: 'pay_subscribe_001',
        kind: PaymentHistoryKind.subscription,
        planLabel: 'Standard · Tháng',
        cycle: BillingCycle.monthly,
        amount: 6589000,
        method: PaymentMethod.vnpayQR,
        status: PaymentStatus.paid,
        createdAt: now.subtract(const Duration(days: 65)),
        settledAt: now.subtract(const Duration(days: 65, minutes: -2)),
        referenceCode: 'VNP-198273645',
        invoiceNumber: 'INV-2026-0011',
      ),
      PaymentHistoryItem(
        id: 'pay_failed_001',
        kind: PaymentHistoryKind.renew,
        planLabel: 'Standard · Tháng',
        cycle: BillingCycle.monthly,
        amount: 6589000,
        method: PaymentMethod.bankTransfer,
        status: PaymentStatus.expired,
        createdAt: now.subtract(const Duration(days: 95)),
        referenceCode: null,
      ),
    ];
  }

  @override
  Future<PaymentSession> renewSubscription({
    required PaymentMethod method,
  }) async {
    // Reuse mock initiatePayment với plan/cycle giả định.
    return initiatePayment(
      planId: 'rooms_10',
      billingCycle: BillingCycle.monthly,
      method: method,
      rooms: 10,
      totalAmount: 6589000,
    );
  }

  String _randomId() => Random().nextInt(999999).toString().padLeft(6, '0');
}
