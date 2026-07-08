import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/admin_bank_account.dart';

/// Queue duyệt tài khoản nhận tiền OWNER (ADMIN). Chuẩn ApiResponse — KHÔNG
/// throw (feature admin/bank ra đời sau nên theo pattern chuẩn, không dùng
/// throw-style như admin/kyc).
class AdminBankRepository {
  final Dio _dio = ApiClient.instance;

  /// GET /admin/bank-accounts?status&page&limit — danh sách theo trạng thái.
  /// `status`: `pending`(default) | `approved` | `rejected` | `all`.
  Future<ApiResponse<AdminBankQueueResult>> fetchQueue({
    String status = 'pending',
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.adminBankAccounts,
        queryParameters: {
          'status': status,
          'page': page,
          'limit': limit,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final items = ((data['items'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(AdminBankAccount.fromJson)
          .toList();
      return ApiResponse(
        success: true,
        data: AdminBankQueueResult(
          items: items,
          pendingCount: (data['pendingCount'] as num?)?.toInt() ?? 0,
          total: (data['total'] as num?)?.toInt() ?? items.length,
        ),
        message: 'OK',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: parseDioError(e),
        code: parseDioErrorCode(e),
      );
    }
  }

  /// POST /admin/users/:id/bank/approve — duyệt (copy pending → live).
  Future<ApiResponse<void>> approve(String userId) async {
    try {
      final response = await _dio.post(ApiConstants.adminBankApprove(userId));
      return ApiResponse(
        success: true,
        message: response.data['message']?.toString() ?? 'Đã duyệt tài khoản',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: parseDioError(e),
        code: parseDioErrorCode(e),
      );
    }
  }

  /// POST /admin/users/:id/bank/reject — từ chối kèm lý do (5–500 ký tự).
  Future<ApiResponse<void>> reject(
    String userId, {
    required String reason,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.adminBankReject(userId),
        data: {'reason': reason},
      );
      return ApiResponse(
        success: true,
        message: response.data['message']?.toString() ?? 'Đã từ chối',
      );
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: parseDioError(e),
        code: parseDioErrorCode(e),
      );
    }
  }
}
