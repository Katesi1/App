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

/// Real backend implementation of [VerifyRepository].
///
/// Calls the endpoints listed in `BACKEND_CHANGES_REPORT.md` sections 4-7.
/// The Dio singleton already has the auth interceptor → every request
/// auto-attaches the bearer token.
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

  /// Multipart upload: image + (optional) OCR JSON already extracted on device.
  ///
  /// Backend just stores the image to Cloudinary + persists the `ocrResult`
  /// JSON in `kyc_uploads.ocr_result`. Does NOT call an external OCR engine
  /// (frontend already extracts via ML Kit / QR scanner on device).
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
        // Optional field — only sent when the scanner extracted data.
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
      final data = res.data['data'] as Map<String, dynamic>;
      // Backend may not yet persist `ocrResult` (early integration) → fall
      // back to the OCR the client sent so frontend can still display data.
      var upload = CCCDUpload.fromJson(data);
      if (upload.ocrResult == null && ocr != null && !ocr.isEmpty) {
        upload = upload.copyWith(ocrResult: ocr);
      }
      return upload.copyWith(localPath: image.path);
    } on DioException catch (e) {
      throw VerifyApiException(parseDioError(e));
    } on TypeError catch (_) {
      // BE returned 200 but the body has a bad schema (null field, wrong type)
      // → cast fails. Convert to a business error so UI shows a friendly
      // message instead of crashing.
      throw const VerifyApiException(
        'Phản hồi máy chủ không hợp lệ. Vui lòng thử lại sau.',
      );
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
    } on TypeError catch (_) {
      // BE returned 200 but the body has a bad schema (null field, wrong type)
      // → cast fails. Convert to a business error so UI shows a friendly
      // message instead of crashing.
      throw const VerifyApiException(
        'Phản hồi máy chủ không hợp lệ. Vui lòng thử lại sau.',
      );
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
    } on TypeError catch (_) {
      // BE returned 200 but the body has a bad schema (null field, wrong type)
      // → cast fails. Convert to a business error so UI shows a friendly
      // message instead of crashing.
      throw const VerifyApiException(
        'Phản hồi máy chủ không hợp lệ. Vui lòng thử lại sau.',
      );
    }
  }

  // ── Billing plans ──────────────────────────────────────────────────────────

  @override
  Future<List<Plan>> fetchPlans() async {
    try {
      final res = await _dio.get(ApiConstants.billingPlans);
      final list = (res.data['data'] as List).cast<Map<String, dynamic>>();
      return list.map(Plan.fromJson).toList();
    } on DioException catch (e) {
      throw VerifyApiException(parseDioError(e));
    } on TypeError catch (_) {
      // BE returned 200 but the body has a bad schema (null field, wrong type)
      // → cast fails. Convert to a business error so UI shows a friendly
      // message instead of crashing.
      throw const VerifyApiException(
        'Phản hồi máy chủ không hợp lệ. Vui lòng thử lại sau.',
      );
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
    } on TypeError catch (_) {
      // BE returned 200 but the body has a bad schema (null field, wrong type)
      // → cast fails. Convert to a business error so UI shows a friendly
      // message instead of crashing.
      throw const VerifyApiException(
        'Phản hồi máy chủ không hợp lệ. Vui lòng thử lại sau.',
      );
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
    } on TypeError catch (_) {
      // BE returned 200 but the body has a bad schema (null field, wrong type)
      // → cast fails. Convert to a business error so UI shows a friendly
      // message instead of crashing.
      throw const VerifyApiException(
        'Phản hồi máy chủ không hợp lệ. Vui lòng thử lại sau.',
      );
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
    } on TypeError catch (_) {
      // BE returned 200 but the body has a bad schema (null field, wrong type)
      // → cast fails. Convert to a business error so UI shows a friendly
      // message instead of crashing.
      throw const VerifyApiException(
        'Phản hồi máy chủ không hợp lệ. Vui lòng thử lại sau.',
      );
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
    } on TypeError catch (_) {
      // BE returned 200 but the body has a bad schema (null field, wrong type)
      // → cast fails. Convert to a business error so UI shows a friendly
      // message instead of crashing.
      throw const VerifyApiException(
        'Phản hồi máy chủ không hợp lệ. Vui lòng thử lại sau.',
      );
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
    } on TypeError catch (_) {
      // BE returned 200 but the body has a bad schema (null field, wrong type)
      // → cast fails. Convert to a business error so UI shows a friendly
      // message instead of crashing.
      throw const VerifyApiException(
        'Phản hồi máy chủ không hợp lệ. Vui lòng thử lại sau.',
      );
    }
  }

  @override
  Future<RefundResult> requestRefund(String submissionId) async {
    // Backend expects `sessionId`, not `submissionId`. Fetch the session from
    // the submission detail then call refund.
    try {
      final detail = await _dio.get(
        ApiConstants.kycSubmissionDetail(submissionId),
      );
      final payment = detail.data['data']['payment'] as Map<String, dynamic>?;
      if (payment == null) {
        throw const VerifyApiException('Không tìm thấy phiên thanh toán');
      }
      final sessionId = payment['id'] as String;
      final res = await _dio.post(ApiConstants.paymentRefund(sessionId));
      final data = res.data['data'] as Map<String, dynamic>;
      return RefundResult(
        refundedAt: _parseDate(data['refundedAt']) ?? DateTime.now(),
        refundAmount: (data['amount'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (e) {
      throw VerifyApiException(parseDioError(e));
    } on TypeError catch (_) {
      // BE returned 200 but the body has a bad schema (null field, wrong type)
      // → cast fails. Convert to a business error so UI shows a friendly
      // message instead of crashing.
      throw const VerifyApiException(
        'Phản hồi máy chủ không hợp lệ. Vui lòng thử lại sau.',
      );
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
    } on TypeError catch (_) {
      // BE returned 200 but the body has a bad schema (null field, wrong type)
      // → cast fails. Convert to a business error so UI shows a friendly
      // message instead of crashing.
      throw const VerifyApiException(
        'Phản hồi máy chủ không hợp lệ. Vui lòng thử lại sau.',
      );
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
    } on TypeError catch (_) {
      // BE returned 200 but the body has a bad schema (null field, wrong type)
      // → cast fails. Convert to a business error so UI shows a friendly
      // message instead of crashing.
      throw const VerifyApiException(
        'Phản hồi máy chủ không hợp lệ. Vui lòng thử lại sau.',
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Get the current submission ID from `/kyc/status` (backend infers it from the token).
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

/// Business error from the KYC backend (carries the server's Vietnamese
/// message or a fallback from `parseDioError`).
class VerifyApiException implements Exception {
  final String message;
  const VerifyApiException(this.message);

  @override
  String toString() => message;
}
