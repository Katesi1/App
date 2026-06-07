import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/staff_permission.dart';

/// `GET/PUT /permissions/:userId` — cấu hình quyền cho 1 nhân viên SALE. ADMIN-only.
class StaffPermissionRepository {
  final Dio _dio = ApiClient.instance;

  Future<ApiResponse<StaffPermissions>> getPermissions(String userId) async {
    try {
      final res = await _dio.get(ApiConstants.userPermissions(userId));
      return ApiResponse(
        success: true,
        data:
            StaffPermissions.fromJson(res.data['data'] as Map<String, dynamic>),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (_) {
      return ApiResponse(
          success: false, message: 'Dữ liệu phân quyền không hợp lệ');
    }
  }

  Future<ApiResponse<void>> updatePermissions(
    String userId,
    List<ModulePermission> modules,
  ) async {
    try {
      await _dio.put(
        ApiConstants.userPermissions(userId),
        data: {'permissions': modules.map((m) => m.toJson()).toList()},
      );
      return ApiResponse(success: true, message: 'Đã lưu phân quyền');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }
}
