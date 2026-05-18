import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../verify/data/models/cccd_upload.dart';
import '../../../verify/data/models/ocr_result.dart';
import '../../../verify/data/models/payment_session.dart';
import '../../../verify/data/models/selfie_upload.dart';
import '../../../verify/data/models/verify_enums.dart';
import '../models/kyc_submission.dart';
import 'admin_kyc_repository.dart';

class AdminKycRepositoryImpl implements AdminKycRepository {
  final Dio _dio;

  AdminKycRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  @override
  Future<List<KYCSubmission>> fetchAll() async {
    try {
      final results = await Future.wait([
        _fetchPage('awaiting_approval'),
        _fetchPage('approved'),
        _fetchPage('rejected'),
      ]);
      return [...results[0], ...results[1], ...results[2]];
    } on DioException catch (e) {
      throw Exception(parseDioError(e));
    } on TypeError catch (_) {
      // BE returned 200 but body has wrong schema → avoid UI crash.
      throw Exception('Phản hồi máy chủ không hợp lệ. Vui lòng thử lại sau.');
    }
  }

  Future<List<KYCSubmission>> _fetchPage(String status) async {
    final res = await _dio.get(
      ApiConstants.adminKycQueue,
      queryParameters: {
        'page': 1,
        'pageSize': 100,
        'status': status,
      },
    );
    final items =
        (res.data['data']['items'] as List).cast<Map<String, dynamic>>();
    return items.map(_listItemToSubmission).toList();
  }

  @override
  Future<KYCSubmission?> fetchById(String id) async {
    try {
      final res = await _dio.get(ApiConstants.kycSubmissionDetail(id));
      final data = res.data['data'] as Map<String, dynamic>;
      return _detailToSubmission(id, data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(parseDioError(e));
    }
  }

  @override
  Future<KYCSubmission> approve(String id, {required String adminName}) async {
    try {
      final res = await _dio.post(
        ApiConstants.adminKycApprove(id),
        data: {'trialDays': 7},
      );
      // Backend returns `{submissionId, status, approvedAt, trialEndsAt}` —
      // build minimal KYCSubmission from response; controller will invalidate
      // `kycSubmissionsProvider` right after so UI refetches full data.
      final data = res.data['data'] as Map<String, dynamic>;
      return _ackSubmission(
        id: id,
        status: VerifyStatus.approved,
        adminName: adminName,
        handledAt: _parseDate(data['approvedAt']) ?? DateTime.now(),
      );
    } on DioException catch (e) {
      throw Exception(parseDioError(e));
    } on TypeError catch (_) {
      // BE returned 200 but body has wrong schema → avoid UI crash.
      throw Exception('Phản hồi máy chủ không hợp lệ. Vui lòng thử lại sau.');
    }
  }


  @override
  Future<KYCSubmission> reject(
    String id, {
    required String adminName,
    required String reason,
    required List<RejectableItem> items,
  }) async {
    try {
      await _dio.post(
        ApiConstants.adminKycReject(id),
        data: {
          'reason': reason,
          'items': items.map((i) => i.id).toList(),
        },
      );
      return _ackSubmission(
        id: id,
        status: VerifyStatus.rejected,
        adminName: adminName,
        handledAt: DateTime.now(),
        rejectReason: reason,
        rejectedItems: items,
      );
    } on DioException catch (e) {
      throw Exception(parseDioError(e));
    } on TypeError catch (_) {
      // BE returned 200 but body has wrong schema → avoid UI crash.
      throw Exception('Phản hồi máy chủ không hợp lệ. Vui lòng thử lại sau.');
    }
  }

  KYCSubmission _ackSubmission({
    required String id,
    required VerifyStatus status,
    required String adminName,
    required DateTime handledAt,
    String? rejectReason,
    List<RejectableItem> rejectedItems = const [],
  }) {
    return KYCSubmission(
      id: id,
      ownerId: '',
      ownerName: '',
      ownerPhone: '',
      cccdFront: _emptyCccd(),
      cccdBack: _emptyCccd(),
      selfie: _emptySelfie(),
      planName: '',
      totalAmount: 0,
      expectedRooms: 0,
      submittedAt: handledAt,
      status: status,
      rejectReason: rejectReason,
      rejectedItems: rejectedItems,
      handledByAdmin: adminName,
      handledAt: handledAt,
    );
  }

  KYCSubmission _listItemToSubmission(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final uploads = (json['uploads'] as Map<String, dynamic>?) ?? const {};
    final rejectedRaw =
        (json['rejectedItems'] as List?)?.cast<String>() ?? const [];

    return KYCSubmission(
      id: json['id'] as String,
      ownerId: user['id'] as String,
      ownerName: (user['name'] as String?) ?? '',
      ownerPhone: (user['phone'] as String?) ?? '',
      ownerEmail: user['email'] as String?,
      cccdFront: _parseCccd(uploads['cccdFront']) ?? _emptyCccd(),
      cccdBack: _parseCccd(uploads['cccdBack']) ?? _emptyCccd(),
      selfie: _parseSelfie(uploads['selfie']) ?? _emptySelfie(),
      planName: _formatPlanName(json['plan'] as String?),
      totalAmount: (json['totalPaid'] as num?)?.toInt() ?? 0,
      expectedRooms: (json['expectedRooms'] as num?)?.toInt() ?? 0,
      submittedAt: _parseDate(json['submittedAt']) ??
          _parseDate(json['createdAt']) ??
          DateTime.now(),
      status: verifyStatusFromApi(json['status'] as String),
      rejectReason: json['rejectReason'] as String?,
      rejectedItems: rejectedRaw
          .map(RejectableItemX.fromId)
          .whereType<RejectableItem>()
          .toList(),
      handledByAdmin: json['handledByAdmin'] as String?,
      handledAt: _parseDate(json['handledAt']),
    );
  }

  KYCSubmission _detailToSubmission(String id, Map<String, dynamic> data) {
    final uploads = (data['uploads'] as Map<String, dynamic>?) ?? const {};
    final payment = data['payment'] as Map<String, dynamic>?;
    final rejectedRaw =
        (data['rejectedItems'] as List?)?.cast<String>() ?? const [];
    return KYCSubmission(
      id: (data['id'] as String?) ?? id,
      ownerId: (data['userId'] as String?) ?? '',
      ownerName: (data['ownerName'] as String?) ?? '',
      ownerPhone: (data['ownerPhone'] as String?) ?? '',
      ownerEmail: data['ownerEmail'] as String?,
      cccdFront: _parseCccd(uploads['cccdFront']) ?? _emptyCccd(),
      cccdBack: _parseCccd(uploads['cccdBack']) ?? _emptyCccd(),
      selfie: _parseSelfie(uploads['selfie']) ?? _emptySelfie(),
      planName: _formatPlanName(payment?['planId'] as String?,
          cycle: payment?['cycle'] as String?),
      totalAmount: (payment?['totalAmount'] as num?)?.toInt() ?? 0,
      expectedRooms: (data['expectedRooms'] as num?)?.toInt() ?? 0,
      submittedAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      status: verifyStatusFromApi(data['status'] as String),
      rejectReason: data['rejectReason'] as String?,
      rejectedItems: rejectedRaw
          .map(RejectableItemX.fromId)
          .whereType<RejectableItem>()
          .toList(),
      handledByAdmin: data['approvedByName'] as String? ??
          data['handledByAdmin'] as String?,
      handledAt:
          _parseDate(data['approvedAt']) ?? _parseDate(data['handledAt']),
    );
  }

  CCCDUpload? _parseCccd(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    return CCCDUpload(
      id: (raw['id'] as String?) ?? '',
      imageUrl: (raw['imageUrl'] as String?) ?? '',
      ocrResult: raw['ocrResult'] is Map<String, dynamic>
          ? OCRResult.fromJson(raw['ocrResult'] as Map<String, dynamic>)
          : null,
      confidence: (raw['confidence'] as num?)?.toDouble() ?? 0,
      uploadedAt: _parseDate(raw['uploadedAt']) ?? DateTime.now(),
    );
  }

  SelfieUpload? _parseSelfie(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final score = (raw['faceMatchScore'] as num?)?.toDouble() ?? 0;
    return SelfieUpload(
      id: (raw['id'] as String?) ?? '',
      imageUrl: (raw['imageUrl'] as String?) ?? '',
      faceMatchScore: score,
      isValid: (raw['isValid'] as bool?) ?? (score >= 0.85),
      uploadedAt: _parseDate(raw['uploadedAt']) ?? DateTime.now(),
    );
  }

  // Helpers.

  /// Formats `"professional"` + `"yearly"` → `"Professional · Hàng năm"`.
  String _formatPlanName(String? planId, {String? cycle}) {
    final name = switch (planId) {
      'starter' => 'Starter',
      'professional' => 'Professional',
      'enterprise' => 'Enterprise',
      null => '—',
      _ => planId.substring(0, 1).toUpperCase() + planId.substring(1),
    };
    final cycleLabel = switch (cycle) {
      'yearly' => 'Hàng năm',
      'monthly' => 'Hàng tháng',
      _ => null,
    };
    return cycleLabel == null ? name : '$name · $cycleLabel';
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null || raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  // Backend sometimes omits image (e.g. OCR pending) — render placeholder
  // instead of crashing UI.
  CCCDUpload _emptyCccd() => CCCDUpload(
        id: '',
        imageUrl: '',
        confidence: 0,
        uploadedAt: DateTime.now(),
      );

  SelfieUpload _emptySelfie() => SelfieUpload(
        id: '',
        imageUrl: '',
        faceMatchScore: 0,
        isValid: false,
        uploadedAt: DateTime.now(),
      );
}
