import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/bank_account_model.dart';

/// Tài khoản nhận tiền của OWNER (BE §3.3). Tạo/sửa phải qua ADMIN duyệt.
class BankRepository {
  final Dio _dio = ApiClient.instance;

  /// GET /users/me/bank — trạng thái tài khoản nhận tiền hiện tại.
  Future<ApiResponse<BankStatusResult>> getBank() async {
    try {
      final response = await _dio.get(ApiConstants.userMeBank);
      final data = response.data['data'];
      if (data is! Map<String, dynamic>) {
        return ApiResponse(
          success: false,
          message: 'Không nhận được dữ liệu từ server',
        );
      }
      return ApiResponse(
        success: true,
        data: BankStatusResult.fromJson(data),
        message: response.data['message'] ?? '',
      );
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }

  /// PUT /users/me/bank — gửi tài khoản mới → BE ghi vào pending, chờ duyệt.
  /// Body: `{ bankBin, bankName?, bankAccountNumber, bankAccountName }`.
  Future<ApiResponse<BankStatusResult>> updateBank(BankDetail detail) async {
    try {
      final response = await _dio.put(
        ApiConstants.userMeBank,
        data: detail.toJson(),
      );
      final data = response.data['data'];
      final result =
          data is Map<String, dynamic> ? BankStatusResult.fromJson(data) : null;
      return ApiResponse(
        success: true,
        data: result,
        message: response.data['message'] ?? 'Đã gửi, chờ quản trị viên duyệt',
      );
    } on DioException catch (e) {
      return ApiResponse.fromDioError(e);
    }
  }
}
