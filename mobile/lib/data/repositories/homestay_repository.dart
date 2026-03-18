import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/homestay_model.dart';

class HomestayRepository {
  final _dio = ApiClient.instance;

  Future<ApiResponse<List<HomestayModel>>> getHomestays() async {
    try {
      final response = await _dio.get(ApiConstants.homestays);
      final list = (response.data['data'] as List)
          .map((e) => HomestayModel.fromJson(e))
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<HomestayModel>> getHomestay(String id) async {
    try {
      final response = await _dio.get('${ApiConstants.homestays}/$id');
      return ApiResponse(
        success: true,
        data: HomestayModel.fromJson(response.data['data']),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<HomestayModel>> createHomestay(
      Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.homestays, data: data);
      return ApiResponse(
        success: true,
        data: HomestayModel.fromJson(response.data['data']),
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<HomestayModel>> updateHomestay(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.put('${ApiConstants.homestays}/$id', data: data);
      return ApiResponse(
        success: true,
        data: HomestayModel.fromJson(response.data['data']),
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<void>> deleteHomestay(String id) async {
    try {
      await _dio.delete('${ApiConstants.homestays}/$id');
      return ApiResponse(success: true, message: 'Xoá homestay thành công');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }
}
