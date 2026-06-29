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
      final list = (response.data['data'] as List).map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        // Nhân viên trả về từ /my-staff = ĐÃ thuộc đội của OWNER hiện tại.
        // Nếu BE không trả `saleMembershipStatus` (và không có `ownerId`),
        // mặc định 'active' để không hiện nhầm badge "Chưa gán owner". Vẫn
        // giữ nguyên state rõ ràng từ BE (invited | suspended).
        final status = (map['saleMembershipStatus'] as String?)?.trim() ?? '';
        if (status.isEmpty && map['ownerId'] == null) {
          map['saleMembershipStatus'] = 'active';
        }
        return UserModel.fromJson(map);
      }).toList();
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

  /// Huỷ yêu cầu xoá tài khoản trong grace period 30 ngày.
  /// 200 → khôi phục thành công.
  /// 400 users.deletionNotPending → không có pending request (race condition).
  Future<ApiResponse<void>> restoreAccount() async {
    try {
      await _dio.post(ApiConstants.userDeletionRestore);
      return ApiResponse(success: true, message: 'Tài khoản đã được khôi phục.');
    } on DioException catch (e) {
      // Giữ `code` (vd users.deletionNotPending) để UI phân biệt "không còn ở
      // trạng thái chờ xoá" với lỗi mạng → xử lý mượt thay vì báo lỗi chung.
      return ApiResponse(
        success: false,
        message: parseDioError(e),
        code: parseDioErrorCode(e),
      );
    }
  }

  /// Trạng thái xoá tài khoản từ server (NĐ 13 / GDPR).
  /// Response data: { pending: bool, scheduledDeleteAt: ISO|null,
  /// daysRemaining: int }. Authoritative hơn cache profile (đồng hồ server).
  Future<ApiResponse<DeletionStatus>> getDeletionStatus() async {
    try {
      final resp = await _dio.get(ApiConstants.userDeletionStatus);
      final data = resp.data?['data'];
      return ApiResponse(
        success: true,
        data: (
          pending: data?['pending'] == true,
          scheduledDeleteAt: data?['scheduledDeleteAt'] as String?,
          daysRemaining: (data?['daysRemaining'] as num?)?.toInt(),
        ),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Self-delete for App Store + GDPR / NĐ 13 compliance.
  /// v1.14: BE không xoá ngay — tạo deletion request với grace period.
  /// Response data: { scheduledDeleteAt: ISO, graceDays: int }.
  /// Login lại trong grace period → BE auto-cancel yêu cầu.
  ///
  /// [reason] optional — sent along so BE can log the reason (analytics).
  Future<ApiResponse<DeletionSchedule>> deleteMyAccount({String? reason}) async {
    try {
      final resp = await _dio.delete(
        '${ApiConstants.users}/me',
        data: reason == null ? null : {'reason': reason},
      );
      final data = resp.data?['data'];
      return ApiResponse(
        success: true,
        data: (
          scheduledDeleteAt: data?['scheduledDeleteAt'] as String?,
          graceDays: (data?['graceDays'] as num?)?.toInt(),
        ),
        message: resp.data?['message'] as String? ??
            'Yêu cầu xoá tài khoản đã được gửi.',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }
}

/// Kết quả yêu cầu xoá tài khoản — ngày xoá dự kiến + số ngày grace từ BE.
typedef DeletionSchedule = ({String? scheduledDeleteAt, int? graceDays});

/// Trạng thái xoá tài khoản hiện tại (GET /users/me/deletion-status).
typedef DeletionStatus = ({
  bool pending,
  String? scheduledDeleteAt,
  int? daysRemaining,
});
