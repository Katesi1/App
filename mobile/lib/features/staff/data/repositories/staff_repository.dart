import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/models/user_model.dart';
import '../models/staff_invite.dart';

/// Kết quả accept invite — sealed để caller exhaustive switch.
sealed class AcceptInviteOutcome {
  const AcceptInviteOutcome();
}

class AcceptInviteSuccess extends AcceptInviteOutcome {
  final UserModel user;
  const AcceptInviteSuccess(this.user);
}

class AcceptInviteFailure extends AcceptInviteOutcome {
  final String message;
  const AcceptInviteFailure(this.message);
}

class StaffRepository {
  final Dio _dio = ApiClient.instance;
  final AuthRepository _authRepo = AuthRepository();

  /// OWNER tạo invite + BE gửi email cho nhân viên.
  Future<ApiResponse<StaffInvite>> createInvite(String email) async {
    try {
      final response = await _dio.post(
        ApiConstants.staffInvites,
        data: {'email': email.trim()},
      );
      final data = response.data['data'];
      Map<String, dynamic>? inviteJson;
      String? inviteLink;
      if (data is Map<String, dynamic>) {
        if (data['invite'] is Map<String, dynamic>) {
          inviteJson = Map<String, dynamic>.from(data['invite'] as Map);
          inviteLink = data['inviteLink'] as String?;
        } else {
          inviteJson = Map<String, dynamic>.from(data);
        }
      }
      if (inviteJson == null) {
        return ApiResponse(
          success: false,
          message: 'Phản hồi tạo lời mời không đúng định dạng',
        );
      }
      if (inviteLink != null) {
        inviteJson['inviteLink'] = inviteLink;
      }
      return ApiResponse(
        success: true,
        data: StaffInvite.fromJson(inviteJson),
        message: response.data['message']?.toString() ?? 'Đã gửi lời mời',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// OWNER list invite của mình.
  Future<ApiResponse<List<StaffInvite>>> listInvites({
    StaffInviteStatus? status,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.staffInvites,
        queryParameters: {
          if (status != null && status != StaffInviteStatus.unknown)
            'status': status.apiValue,
        },
      );
      final list = (response.data['data'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StaffInvite.fromJson)
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// OWNER huỷ invite.
  Future<ApiResponse<void>> cancelInvite(String inviteId) async {
    try {
      final response = await _dio.delete(
        ApiConstants.staffInviteDetail(inviteId),
      );
      return ApiResponse(
        success: true,
        message: response.data['message']?.toString() ?? 'Đã huỷ lời mời',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Public — verify token/short code để hiện màn confirm cho user.
  Future<ApiResponse<StaffInvitePreview>> verifyInvite(String token) async {
    try {
      final response = await _dio.get(
        ApiConstants.staffInviteVerify(token.trim()),
      );
      final data = response.data['data'];
      if (data is! Map<String, dynamic>) {
        return ApiResponse(
          success: false,
          message: 'Phản hồi không đúng định dạng',
        );
      }
      return ApiResponse(
        success: true,
        data: StaffInvitePreview.fromJson(data),
        message: '',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// Public — accept invite bằng Google idToken.
  Future<AcceptInviteOutcome> acceptWithGoogle({
    required String token,
    required String idToken,
  }) async {
    return _accept(body: {
      'token': token.trim(),
      'method': 'google',
      'idToken': idToken,
    });
  }

  /// Public — accept invite bằng email/password.
  Future<AcceptInviteOutcome> acceptWithPassword({
    required String token,
    required String name,
    required String password,
    String? phone,
  }) async {
    return _accept(body: {
      'token': token.trim(),
      'method': 'password',
      'name': name.trim(),
      'password': password,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    });
  }

  Future<AcceptInviteOutcome> _accept(
      {required Map<String, dynamic> body}) async {
    try {
      final response = await _dio.post(
        ApiConstants.staffInviteAccept,
        data: body,
      );
      final payload = response.data['data'];
      if (payload is! Map<String, dynamic>) {
        return const AcceptInviteFailure(
          'Phản hồi accept invite không đúng định dạng',
        );
      }
      final access = payload['accessToken'] as String?;
      final refresh = payload['refreshToken'] as String?;
      if (access == null ||
          refresh == null ||
          access.isEmpty ||
          refresh.isEmpty) {
        return const AcceptInviteFailure('Thiếu token từ máy chủ');
      }

      await SecureStorage.saveAccessToken(access);
      await SecureStorage.saveRefreshToken(refresh);

      final profile = await _authRepo.getProfile();
      if (!profile.success || profile.data == null) {
        return AcceptInviteFailure(
          profile.message.isNotEmpty
              ? profile.message
              : 'Không lấy được thông tin người dùng sau accept invite',
        );
      }
      return AcceptInviteSuccess(profile.data!);
    } on DioException catch (e) {
      return AcceptInviteFailure(parseDioError(e));
    } catch (e) {
      return AcceptInviteFailure('Accept invite thất bại: $e');
    }
  }

  /// OWNER list nhân viên hiện tại.
  Future<ApiResponse<List<UserModel>>> listStaff({bool? isActive}) async {
    try {
      final response = await _dio.get(
        ApiConstants.staff,
        queryParameters: {
          if (isActive != null) 'isActive': isActive,
        },
      );
      final list = (response.data['data'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(UserModel.fromJson)
          .toList();
      return ApiResponse(success: true, data: list, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// OWNER soft-delete nhân viên.
  Future<ApiResponse<void>> removeStaff(String userId) async {
    try {
      final response = await _dio.delete(ApiConstants.staffDetail(userId));
      return ApiResponse(
        success: true,
        message: response.data['message']?.toString() ?? 'Đã xoá nhân viên',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }
}
