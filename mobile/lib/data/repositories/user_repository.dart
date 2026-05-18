import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/user_model.dart';

class UserRepository {
  final _dio = ApiClient.instance;

  Future<ApiResponse<UserModel>> getUser(String id) async {
    try {
      final response = await _dio.get(ApiConstants.userDetail(id));
      return ApiResponse(
        success: true,
        data: UserModel.fromJson(response.data['data']),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<List<UserModel>>> getUsers({int? role}) async {
    try {
      final response = await _dio.get(
        ApiConstants.users,
        queryParameters: role != null ? {'role': role} : null,
      );
      final list = (response.data['data'] as List)
          .map((e) => UserModel.fromJson(e))
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Get my staff list (OWNER only).
  Future<ApiResponse<List<UserModel>>> getMyStaff() async {
    try {
      final response = await _dio.get('${ApiConstants.users}/my-staff');
      final list = (response.data['data'] as List)
          .map((e) => UserModel.fromJson(e))
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Get the list of SALE without an owner (OWNER uses this to add staff).
  Future<ApiResponse<List<UserModel>>> getAvailableStaff() async {
    try {
      final response = await _dio.get('${ApiConstants.users}/available-staff');
      final list = (response.data['data'] as List)
          .map((e) => UserModel.fromJson(e))
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Add staff to my team (OWNER only).
  Future<ApiResponse<UserModel>> addMyStaff(String email) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.users}/my-staff',
        data: {'email': email},
      );
      return ApiResponse(
        success: true,
        data: UserModel.fromJson(response.data['data']),
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Remove staff from my team (OWNER only).
  Future<ApiResponse<void>> removeMyStaff(String id) async {
    try {
      await _dio.delete('${ApiConstants.users}/my-staff/$id');
      return ApiResponse(success: true, message: 'Đã gỡ nhân viên');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<UserModel>> createUser(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.users, data: data);
      return ApiResponse(
        success: true,
        data: UserModel.fromJson(response.data['data']),
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<UserModel>> updateUser(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('${ApiConstants.users}/$id', data: data);
      return ApiResponse(
        success: true,
        data: UserModel.fromJson(response.data['data']),
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<void>> deleteUser(String id) async {
    try {
      await _dio.delete('${ApiConstants.users}/$id');
      return ApiResponse(success: true, message: 'Xoá người dùng thành công');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Self-delete for App Store + GDPR compliance.
  /// Currently reuses `DELETE /users/:id` — BE needs to confirm this endpoint
  /// allows user self-delete (not just ADMIN). If BE doesn't allow it yet,
  /// it returns 403 and FE shows a clear error so the user can contact support.
  ///
  /// [reason] optional — sent along so BE can log the reason (analytics).
  Future<ApiResponse<void>> deleteMyAccount({String? reason}) async {
    try {
      await _dio.delete(
        '${ApiConstants.users}/me',
        data: reason == null ? null : {'reason': reason},
      );
      return ApiResponse(
        success: true,
        message: 'Đã xoá tài khoản. Hẹn gặp lại bạn!',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }
}
