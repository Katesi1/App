import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/cccd_upload.dart';
import '../models/ocr_result.dart';
import '../models/payment_history_item.dart';
import '../models/payment_session.dart';
import '../models/plan.dart';
import '../models/selfie_upload.dart';
import '../models/verify_enums.dart';
import 'verify_repository.dart';

/// Real backend implementation cho [VerifyRepository].
///
/// Gọi các endpoint tại spec `BACKEND_CHANGES_REPORT.md` mục 4-7.
/// Dio singleton có sẵn auth interceptor → mọi request tự đính bearer token.
class VerifyRepositoryImpl implements VerifyRepository {
  final Dio _dio;

  VerifyRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  // ── KYC upload ─────────────────────────────────────────────────────────────

  @override
  Future<CCCDUpload> uploadCCCDFront(File image, {OCRResult? ocrResult}) =>
      _uploadCccd(ApiConstants.kycUploadCccdFront, image, ocrResult);

  @override
  Future<CCCDUpload> uploadCCCDBack(File image, {OCRResult? ocrResult}) =>
      _uploadCccd(ApiConstants.kycUploadCccdBack, image, ocrResult);

  /// Multipart upload: ảnh + (optional) OCR JSON đã extract trên device.
  ///
  /// Backend chỉ cần lưu ảnh lên Cloudinary + lưu `ocrResult` JSON vào
  /// `kyc_uploads.ocr_result`. KHÔNG gọi OCR engine bên ngoài (frontend đã
  /// extract bằng ML Kit / QR scanner trên device).
  Future<CCCDUpload> _uploadCccd(
    String path,
    File image,
    OCRResult? ocr,
  ) async {
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        ),
        // Field optional — chỉ gửi khi scanner extract được data
        if (ocr != null && !ocr.isEmpty) 'ocrResult': jsonEncode(ocr.toJson()),
      });
      final res = await _dio.post(
        path,
        data: form,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final raw = res.data['data'];
      if (raw is! Map<String, dynamic>) {
        throw const VerifyApiException('Invalid response format');
      }
      final data = raw;
      // Backend có thể chưa lưu `ocrResult` (early integration) → fallback
      // dùng ocr client đã gửi để frontend vẫn có data hiển thị ngay.
      var upload = CCCDUpload.fromJson(data);
      if (upload.ocrResult == null && ocr != null && !ocr.isEmpty) {
        upload = upload.copyWith(ocrResult: ocr);
      }
      return upload.copyWith(localPath: image.path);
    } on DioException catch (e) {
      throw VerifyApiException(parseDioError(e));
    }
  }

  @override
  Future<SelfieUpload> uploadSelfie(File image,
      {required String cccdFrontId}) async {
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        ),
        'cccdFrontId': cccdFrontId,
      });
      final res = await _dio.post(
        ApiConstants.kycUploadSelfie,
        data: form,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return SelfieUpload.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw VerifyApiException(parseDioError(e));
    }
  }

  // ── Status snapshot ────────────────────────────────────────────────────────

  @override
  Future<KycStatusSnapshot> getKycStatus() async {
    try {
      final res = await _dio.get(ApiConstants.kycStatus);
      final data = res.data['data'] as Map<String, dynamic>;
      final uploads = (data['uploads'] as Map<String, dynamic>?) ?? const {};
      final rejectedItemsRaw =
          (data['rejectedItems'] as List?)?.cast<String>() ?? const [];
      return KycStatusSnapshot(
        status: verifyStatusFromApi(data['status'] as String),
        submissionId: data['submissionId'] as String?,
        rejectReason: data['rejectReason'] as String?,
        rejectedItems: rejectedItemsRaw
            .map(RejectableItemX.fromId)
            .whereType<RejectableItem>()
            .toList(),
        approvedAt: _parseDate(data['approvedAt']),
        trialEndsAt: _parseDate(data['trialEndsAt']),
        hasCccdFront: uploads['cccdFront'] == true,
        hasCccdBack: uploads['cccdBack'] == true,
        hasSelfie: uploads['selfie'] == true,
      );
    } on DioException catch (e) {
      throw VerifyApiException(parseDioError(e));
    }
  }

  // ── Billing plans ──────────────────────────────────────────────────────────

  @override
  Future<List<Plan>> fetchPlans() async {
    try {
      final res = await _dio.get(ApiConstants.billingPlans);
      final rawList = res.data['data'];
      if (rawList is! List) throw const VerifyApiException('Invalid response format');
      final list = rawList.cast<Map<String, dynamic>>();
      return list.map(Plan.fromJson).toList();
    } on DioException catch (e) {
      throw VerifyApiException(parseDioError(e));
    }
  }

  // ── Payment ────────────────────────────────────────────────────────────────

  @override
  Future<PaymentSession> initiatePayment({
    required String planId,
    required BillingCycle billingCycle,
    required PaymentMethod method,
    required int rooms,
    required int totalAmount,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.paymentInitiate,
        data: {
          'planId': planId,
          'cycle': billingCycle.name,
          'method': method.toApiString(),
          'rooms': rooms,
          'totalAmount': totalAmount,
        },
      );
      return PaymentSession.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw VerifyApiException(parseDioError(e));
    }
  }

  @override
  Future<PaymentStatus> checkPaymentStatus(String sessionId) async {
    try {
      final res = await _dio.get(ApiConstants.paymentStatus(sessionId));
      final data = res.data['data'] as Map<String, dynamic>;
      return paymentStatusFromApi(data['status'] as String);
    } on DioException catch (e) {
      throw VerifyApiException(parseDioError(e));
    }
  }

  // ── Submit / approval / resubmit / refund ──────────────────────────────────

  @override
  Future<SubmissionResult> submitForApproval() async {
    try {
      final res = await _dio.post(ApiConstants.kycSubmit);
      final data = res.data['data'] as Map<String, dynamic>;
      return SubmissionResult(
        submissionId: data['submissionId'] as String,
        status: verifyStatusFromApi(data['status'] as String),
        submittedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      throw VerifyApiException(parseDioError(e));
    }
  }

  @override
  Future<ApprovalResult> checkApprovalStatus(String submissionId) async {
    try {
      final res =
          await _dio.get(ApiConstants.kycSubmissionDetail(submissionId));
      final data = res.data['data'] as Map<String, dynamic>;
      final rejectedItemsRaw =
          (data['rejectedItems'] as List?)?.cast<String>() ?? const [];
      return ApprovalResult(
        status: verifyStatusFromApi(data['status'] as String),
        approvedAt: _parseDate(data['approvedAt']),
        trialEndsAt: _parseDate(data['trialEndsAt']),
        chargeStartsAt: _parseDate(data['chargeStartsAt']),
        rejectReason: data['rejectReason'] as String?,
        rejectedItems: rejectedItemsRaw
            .map(RejectableItemX.fromId)
            .whereType<RejectableItem>()
            .toList(),
      );
    } on DioException catch (e) {
      throw VerifyApiException(parseDioError(e));
    }
  }

  @override
  Future<void> resubmit({required List<RejectableItem> items}) async {
    final submissionId = await _resolveCurrentSubmissionId();
    try {
      await _dio.post(
        ApiConstants.kycSubmissionResubmit(submissionId),
        data: {'items': items.map((i) => i.id).toList()},
      );
    } on DioException catch (e) {
      throw VerifyApiException(parseDioError(e));
    }
  }

  @override
  Future<RefundResult> requestRefund(String submissionId) async {
    // Backend nhận `sessionId`, không phải `submissionId`. Lấy session từ
    // chi tiết submission rồi gọi refund.
    try {
      final detail = await _dio.get(
        ApiConstants.kycSubmissionDetail(submissionId),
      );
      final payment = detail.data['data']['payment'] as Map<String, dynamic>?;
      if (payment == null) {
        throw const VerifyApiException('Không tìm thấy phiên thanh toán');
      }
      final sessionId = (payment['id'] as String?) ?? '';
      final res = await _dio.post(ApiConstants.paymentRefund(sessionId));
      final data = res.data['data'] as Map<String, dynamic>;
      return RefundResult(
        refundedAt: _parseDate(data['refundedAt']) ?? DateTime.now(),
        refundAmount: (data['amount'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (e) {
      throw VerifyApiException(parseDioError(e));
    }
  }

  // ── Subscription history + renew ───────────────────────────────────────────

  @override
  Future<PaymentHistoryPage> fetchPaymentHistory({
    int limit = 50,
    String? cursor,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.paymentHistory,
        queryParameters: {
          'limit': limit,
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        },
      );
      return PaymentHistoryPage.fromResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw VerifyApiException(parseDioError(e));
    }
  }

  @override
  Future<PaymentSession> renewSubscription({
    required PaymentMethod method,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.paymentRenew,
        data: {'method': method.toApiString()},
      );
      return PaymentSession.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw VerifyApiException(parseDioError(e));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Lấy submission ID hiện tại từ `/kyc/status` (backend tự suy ra theo token).
  Future<String> _resolveCurrentSubmissionId() async {
    final snapshot = await getKycStatus();
    final id = snapshot.submissionId;
    if (id == null) {
      throw const VerifyApiException(
        'Chưa có hồ sơ KYC để thực hiện thao tác này.',
      );
    }
    return id;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null || raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

/// Lỗi nghiệp vụ khi gọi backend KYC (đã có message tiếng Việt từ server hoặc
/// message fallback từ `parseDioError`).
class VerifyApiException implements Exception {
  final String message;
  const VerifyApiException(this.message);

  @override
  String toString() => message;
}
