import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../data/models/user_model.dart';
import '../models/user_permission.dart';

/// Data layer cho phân quyền per-user (SALE hệ thống). Ghép API thật BE §12 +
/// §26. Theo chuẩn ApiResponse pattern (KHÔNG throw-style).
class PermissionRepository {
  final Dio _dio = ApiClient.instance;

  /// Danh sách SALE hệ thống (`scope=system`) — ADMIN only (BE §26.3.2).
  /// Ưu tiên query server-side; lọc lại `isSystemSale` phòng khi BE bỏ qua query.
  Future<ApiResponse<List<UserModel>>> listSystemStaff() async {
    try {
      final response = await _dio.get(
        ApiConstants.users,
        queryParameters: {'scope': 'system'},
      );
      final list = (response.data['data'] as List? ?? [])
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
          .where((u) => u.isSystemSale)
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }

  /// Lấy quyền hiện tại của 1 user — `GET /permissions/:userId`.
  Future<ApiResponse<List<UserPermission>>> getPermissions(
    String userId,
  ) async {
    try {
      final response = await _dio.get(ApiConstants.permissions(userId));
      final permissions =
          (response.data['data']?['permissions'] as List? ?? [])
              .map((e) => UserPermission.fromJson(e as Map<String, dynamic>))
              .toList();
      return ApiResponse(success: true, data: permissions, message: '');
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }

  /// Lưu quyền (bulk upsert) — `PUT /permissions/:userId`.
  Future<ApiResponse<void>> updatePermissions(
    String userId,
    List<UserPermission> permissions,
  ) async {
    try {
      await _dio.put(
        ApiConstants.permissions(userId),
        data: {'permissions': permissions.map((p) => p.toJson()).toList()},
      );
      return ApiResponse(success: true, message: 'Đã lưu phân quyền');
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }
}
