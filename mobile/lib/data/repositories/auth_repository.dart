import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _dio = ApiClient.instance;
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '1097115636577-r04cfgplsrd4ql3dtr1d6qcrveb4lidh.apps.googleusercontent.com',
  );

  Future<ApiResponse<UserModel>> register({
    required String name,
    required String email,
    required String password,
    required int role,
    String? phone,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      final data = response.data['data'];

      await SecureStorage.saveAccessToken(data['accessToken']);
      await SecureStorage.saveRefreshToken(data['refreshToken']);

      final user = UserModel.fromJson(data['user']);
      await SecureStorage.saveUserData(user.toJsonString());

      return ApiResponse(
          success: true, data: user, message: 'Đăng ký thành công');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<UserModel>> login(
      String identifier, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'identifier': identifier.trim(),
          'password': password,
        },
      );
      final data = response.data['data'];

      await SecureStorage.saveAccessToken(data['accessToken']);
      await SecureStorage.saveRefreshToken(data['refreshToken']);

      // Login API đã trả về user object — dùng trực tiếp, không cần gọi /profile
      final user = UserModel.fromJson(data['user']);
      await SecureStorage.saveUserData(user.toJsonString());

      return ApiResponse(
          success: true, data: user, message: 'Đăng nhập thành công');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  /// [role] chỉ cần khi user mới (đăng ký qua Google lần đầu)
  Future<ApiResponse<UserModel>> loginWithGoogle({int? role}) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return ApiResponse(success: false, message: 'Đã huỷ đăng nhập Google');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        return ApiResponse(
            success: false, message: 'Không lấy được token từ Google');
      }

      // Gửi idToken lên backend, kèm role nếu có (cho user mới)
      final response = await _dio.post(
        ApiConstants.googleLogin,
        data: {
          'idToken': idToken,
          if (role != null) 'role': role,
        },
      );
      final data = response.data['data'];

      await SecureStorage.saveAccessToken(data['accessToken']);
      await SecureStorage.saveRefreshToken(data['refreshToken']);

      final user = UserModel.fromJson(data['user']);
      await SecureStorage.saveUserData(user.toJsonString());

      return ApiResponse(
          success: true, data: user, message: 'Đăng nhập thành công');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (e) {
      return ApiResponse(
          success: false, message: 'Đăng nhập Google thất bại: $e');
    }
  }

  /// GET /auth/profile — đồng bộ user sau khi mở app / làm mới phiên.
  Future<ApiResponse<UserModel>> getProfile() async {
    try {
      final response = await _dio.get(ApiConstants.profile);
      final raw = response.data['data'];
      if (raw is! Map<String, dynamic>) {
        return ApiResponse(
          success: false,
          message: 'Dữ liệu profile không hợp lệ',
        );
      }
      final user = UserModel.fromJson(raw);
      await SecureStorage.saveUserData(user.toJsonString());
      return ApiResponse(success: true, data: user, message: '');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<void> saveUserLocal(UserModel user) async {
    await SecureStorage.saveUserData(user.toJsonString());
  }

  Future<ApiResponse<void>> forgotPassword(String identifier) async {
    try {
      final response = await _dio.post(
        ApiConstants.forgotPassword,
        data: {'identifier': identifier},
      );
      return ApiResponse(
        success: true,
        message: response.data['message'] ?? 'Đã gửi mã xác nhận',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<void>> resetPassword(
      String token, String newPassword) async {
    try {
      final response = await _dio.post(
        ApiConstants.resetPassword,
        data: {'token': token, 'newPassword': newPassword},
      );
      return ApiResponse(
        success: true,
        message: response.data['message'] ?? 'Đặt lại mật khẩu thành công',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<void>> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final response = await _dio.post(
        ApiConstants.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      return ApiResponse(
        success: true,
        message: response.data['message'] ?? 'Đổi mật khẩu thành công',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<ApiResponse<UserModel>> updateProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.put(ApiConstants.userDetail(userId), data: data);
      final user = UserModel.fromJson(response.data['data']);
      await SecureStorage.saveUserData(user.toJsonString());
      return ApiResponse(
        success: true,
        data: user,
        message: response.data['message'] ?? 'Cập nhật thành công',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    }
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _dio.post(ApiConstants.logout);
    } catch (_) {}
    await SecureStorage.clear();
  }

  Future<UserModel?> getStoredUser() async {
    final json = await SecureStorage.getUserData();
    if (json == null) return null;
    return UserModel.fromJsonString(json);
  }

  Future<bool> isLoggedIn() async {
    final token = await SecureStorage.getAccessToken();
    return token != null;
  }
}
