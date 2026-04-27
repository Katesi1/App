import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';

class DashboardRepository {
  final _dio = ApiClient.instance;

  Future<ApiResponse<Map<String, dynamic>>> getStats() async {
    try {
      final response = await _dio.get(ApiConstants.dashboardStats);
      return ApiResponse(
        success: true,
        data: response.data['data'] as Map<String, dynamic>,
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }
}
