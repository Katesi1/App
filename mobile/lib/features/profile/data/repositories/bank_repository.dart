import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/bank_account.dart';

/// Tài khoản nhận tiền OWNER (admin duyệt). Chuẩn ApiResponse — KHÔNG throw.
class BankRepository {
  final Dio _dio = ApiClient.instance;

  /// GET /users/me/bank — trạng thái + tài khoản hiện tại/đang chờ.
  Future<ApiResponse<BankStatusResult>> getMyBank() async {
    try {
      final response = await _dio.get(ApiConstants.myBank);
      final data = BankStatusResult.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
      return ApiResponse(success: true, data: data, message: 'OK');
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        message: parseDioError(e),
        code: parseDioErrorCode(e),
      );
    }
  }

  /// PUT /users/me/bank — gửi/sửa. Thành công → status = pending (chờ duyệt).
  Future<ApiResponse<BankStatusResult>> submitBank(BankInfo info) async {
    try {
      final response =
          await _dio.put(ApiConstants.myBank, data: info.toJson());
      final data = BankStatusResult.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
      return ApiResponse(
        success: true,
        data: data,
        message: response.data['message']?.toString() ?? 'Đã gửi để duyệt',
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
