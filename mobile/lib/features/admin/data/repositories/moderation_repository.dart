import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/moderation_models.dart';

/// ADMIN moderation API — disputes (khiếu nại) + audit log.
/// Endpoint theo `docs/API_SPEC_FULL.md` §13 / §14. Pagination "Shape A"
/// (`data.items`), nên `_items()` đọc `data['items']` (fallback list trực tiếp).
class ModerationRepository {
  final Dio _dio = ApiClient.instance;

  Future<ApiResponse<List<DisputeModel>>> getDisputes({
    String? status,
    String? type,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.adminDisputes,
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (type != null && type.isNotEmpty) 'type': type,
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );
      final list =
          _items(res.data).map((e) => DisputeModel.fromJson(e)).toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(
          success: false, message: 'Dữ liệu khiếu nại không hợp lệ');
    }
  }

  Future<ApiResponse<List<AuditEntry>>> getAuditLog({
    String? action,
    String? targetType,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.adminAuditLog,
        queryParameters: {
          if (action != null && action.isNotEmpty) 'action': action,
          if (targetType != null && targetType.isNotEmpty)
            'targetType': targetType,
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );
      final list = _items(res.data).map((e) => AuditEntry.fromJson(e)).toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(
          success: false, message: 'Dữ liệu nhật ký không hợp lệ');
    }
  }

  /// Extract list từ body: `{ data: { items: [...] } }` (Shape A) hoặc
  /// `{ data: [...] }` (plain array).
  List<Map<String, dynamic>> _items(dynamic body) {
    final data = body is Map ? body['data'] : null;
    final raw = data is Map ? data['items'] : data;
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }
}
