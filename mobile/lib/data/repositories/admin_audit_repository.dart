import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/audit_log_model.dart';

/// Truy vấn nhật ký audit / moderation admin (`GET /admin/audit-log`).
/// Theo pattern ApiResponse chuẩn — KHÔNG throw (xem CLAUDE.md §10).
class AdminAuditRepository {
  final _dio = ApiClient.instance;

  Future<ApiResponse<AuditLogPage>> getAuditLog({
    String? action,
    String? targetType,
    String? actorId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.adminAuditLog,
        queryParameters: {
          if (action != null && action.isNotEmpty) 'action': action,
          if (targetType != null && targetType.isNotEmpty)
            'targetType': targetType,
          if (actorId != null && actorId.isNotEmpty) 'actorId': actorId,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          'page': page,
          'limit': limit,
        },
      );
      final raw = response.data['data'];
      final page0 = raw is Map<String, dynamic>
          ? AuditLogPage.fromJson(raw)
          : const AuditLogPage();
      return ApiResponse(success: true, data: page0, message: '');
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }
}
