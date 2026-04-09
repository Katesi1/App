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
}
