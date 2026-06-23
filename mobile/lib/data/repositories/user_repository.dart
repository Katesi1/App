import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../features/profile/data/models/account_deletion_schedule.dart';
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
      final list = (response.data['data'] as List? ?? [])
          .map((e) => UserModel.fromJson(e))
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Lấy danh sách nhân viên của tôi (OWNER only)
  Future<ApiResponse<List<UserModel>>> getMyStaff() async {
    try {
      final response = await _dio.get('${ApiConstants.users}/my-staff');
      final list = (response.data['data'] as List? ?? [])
          .map((e) => UserModel.fromJson(e))
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Lấy danh sách SALE chưa có owner (OWNER dùng để add)
  Future<ApiResponse<List<UserModel>>> getAvailableStaff() async {
    try {
      final response = await _dio.get('${ApiConstants.users}/available-staff');
      final list = (response.data['data'] as List? ?? [])
          .map((e) => UserModel.fromJson(e))
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Thêm nhân viên vào đội (OWNER only)
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

  /// Gỡ nhân viên khỏi đội (OWNER only)
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

  /// Self-delete cho compliance App Store / Play Store / GDPR + NĐ 13.
  ///
  /// BE v1.14+: KHÔNG xoá ngay mà tạo deletion request pending, đặt lịch xoá
  /// sau 30 ngày (`data.scheduledDeleteAt` + `data.graceDays`). Đăng nhập lại
  /// trong grace period sẽ tự huỷ yêu cầu (BE auto-cancel, FE không gọi gì).
  ///
  /// [reason] optional — gửi kèm để BE log lý do user xoá (analytics).
  Future<ApiResponse<AccountDeletionSchedule>> deleteMyAccount({
    String? reason,
  }) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.users}/me',
        data: reason == null ? null : {'reason': reason},
      );
      // BE mới trả data.scheduledDeleteAt; BE cũ trả data=null → schedule null,
      // UI fallback message chung (vẫn logout đúng).
      final data = response.data?['data'];
      final schedule =
          data is Map<String, dynamic> && data['scheduledDeleteAt'] != null
              ? AccountDeletionSchedule.fromJson(data)
              : null;
      return ApiResponse(
        success: true,
        data: schedule,
        message: response.data?['message']?.toString() ??
            'Đã gửi yêu cầu xoá tài khoản.',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }
}
