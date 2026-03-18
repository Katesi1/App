import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _dio = ApiClient.instance;

  Future<ApiResponse<UserModel>> login(String phone, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'phone': phone, 'password': password},
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

  Future<void> logout() async {
    try {
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
