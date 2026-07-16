import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/abuse_report.dart';
import 'abuse_report_repository.dart';

/// Real impl — wire "Báo cáo vi phạm" vào backend Disputes (`/admin/disputes`).
///
/// Ánh xạ nghiệp vụ:
/// - report ↔ dispute
/// - "bỏ qua" (dismiss) ↔ `POST /admin/disputes/:id/reject`
/// - "xử lý" (resolve) ↔ `POST /admin/disputes/:id/resolve`
/// - "điều tra" (investigate) ↔ `POST /admin/disputes/:id/investigate`
///
/// Throw-style (giống [VerifyRepository]/[AdminKycRepository]) — throw
/// `Exception` khi lỗi, KHÔNG dùng ApiResponse. Controller đã bắt exception.
class AbuseReportRepositoryImpl implements AbuseReportRepository {
  final Dio _dio;

  AbuseReportRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  // reject/resolve yêu cầu resolution ≥ 5 ký tự.
  static const String _dismissReason = 'Báo cáo không đủ căn cứ — đã bỏ qua.';

  @override
  Future<List<AbuseReport>> fetchAll() async {
    try {
      final res = await _dio.get(
        ApiConstants.adminDisputes,
        queryParameters: {'page': 1, 'limit': 100},
      );
      // Shape A: data = { items, total, page, limit, totalPages }.
      final dataBlock = res.data['data'] as Map<String, dynamic>? ?? {};
      final items =
          ((dataBlock['items'] as List?) ?? const []).cast<Map<String, dynamic>>();
      return items.map(AbuseReport.fromDisputeJson).toList();
    } on DioException catch (e) {
      throw Exception(parseDioError(e));
    }
  }

  @override
  Future<AbuseReport?> fetchById(String id) async {
    try {
      final res = await _dio.get(ApiConstants.adminDisputeDetail(id));
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return AbuseReport.fromDisputeJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(parseDioError(e));
    }
  }

  @override
  Future<AbuseReport> investigate(String id, {required String adminName}) async {
    // adminName không gửi lên — BE ghi actor từ Bearer token.
    return _act(id, () => _dio.post(ApiConstants.adminDisputeInvestigate(id)));
  }

  @override
  Future<AbuseReport> dismiss(String id, {required String adminName}) async {
    return _act(
      id,
      () => _dio.post(
        ApiConstants.adminDisputeReject(id),
        data: {'resolution': _dismissReason},
      ),
    );
  }

  @override
  Future<AbuseReport> resolve(
    String id, {
    required String adminName,
    required String resolution,
    bool hideContent = false,
    bool banUser = false,
  }) async {
    // `hideContent` không có field API tương ứng → nối vào ghi chú để lưu vết.
    final extras = <String>[
      if (hideContent) 'Đã ẩn nội dung',
    ];
    final note = extras.isEmpty
        ? resolution
        : '$resolution (${extras.join(', ')})';

    return _act(
      id,
      () => _dio.post(
        ApiConstants.adminDisputeResolve(id),
        data: {
          'resolution': note,
          // banUser → penalty enum (BE không tự ban, chỉ lưu penalty).
          if (banUser) 'penalty': 'ban_temp',
        },
      ),
    );
  }

  /// Chạy action rồi re-fetch detail để trả state mới nhất từ BE.
  Future<AbuseReport> _act(
    String id,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on DioException catch (e) {
      throw Exception(parseDioError(e));
    }
    final updated = await fetchById(id);
    if (updated == null) {
      throw Exception('Không tìm thấy báo cáo sau khi cập nhật');
    }
    return updated;
  }
}
