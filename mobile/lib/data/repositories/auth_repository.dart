import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/services/device_id_service.dart';
import '../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

/// Profile Google trả khi user mới — FE dùng để hiện preview trên RolePickerScreen.
class GoogleProfile {
  final String email;
  final String name;
  final String? avatar;
  final String sub;

  const GoogleProfile({
    required this.email,
    required this.name,
    this.avatar,
    required this.sub,
  });

  factory GoogleProfile.fromJson(Map<String, dynamic> json) => GoogleProfile(
        email: json['email'] as String,
        name: json['name'] as String? ?? '',
        avatar: json['avatar'] as String?,
        sub: json['sub'] as String,
      );
}

/// Kết quả Google Sign-In. Sealed để caller exhaustive switch.
sealed class GoogleSignInOutcome {
  const GoogleSignInOutcome();
}

/// Login/Register thành công — đã có tokens + user.
class GoogleSignInSuccess extends GoogleSignInOutcome {
  final UserModel user;
  const GoogleSignInSuccess(this.user);
}

/// User mới, BE yêu cầu chọn role. UI push RolePickerScreen kèm [idToken] +
/// [profile] để gọi lại `/auth/google` sau khi chọn xong.
class GoogleSignInNeedsRole extends GoogleSignInOutcome {
  final String idToken;
  final GoogleProfile profile;
  const GoogleSignInNeedsRole({required this.idToken, required this.profile});
}

/// User huỷ pop-up Google.
class GoogleSignInCancelled extends GoogleSignInOutcome {
  const GoogleSignInCancelled();
}

/// Lỗi (network, BE reject, idToken sai...).
class GoogleSignInFailure extends GoogleSignInOutcome {
  final String message;
  const GoogleSignInFailure(this.message);
}

class AuthRepository {
  final _dio = ApiClient.instance;
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '492063080427-ohk8k1tu4nhsdls0lhvh3ia0q4ghgioi.apps.googleusercontent.com',
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
        options: Options(headers: await _antiSpamHeaders()),
      );
      final payload = _extractAuthPayload(response.data);
      if (payload == null) {
        return ApiResponse(
          success: false,
          message: _extractMessage(response.data) ??
              'Phản hồi đăng ký không đúng định dạng',
        );
      }
      final tokens = _extractTokens(payload);
      if (tokens == null || tokens.$1.isEmpty || tokens.$2.isEmpty) {
        return ApiResponse(
          success: false,
          message: 'Thiếu access/refresh token từ máy chủ',
        );
      }

      return _completeAuthSession(
        accessToken: tokens.$1,
        refreshToken: tokens.$2,
        successMessage: 'Đăng ký thành công',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (e) {
      return ApiResponse(success: false, message: 'Đăng ký thất bại: $e');
    }
  }

  /// Login với email (+ phone khi BE deploy `identifier` field).
  ///
  /// ⚠️ Hiện tại BE DTO vẫn có `@IsEmail()` trên field `email` — login phone
  /// trả 400 "Email không hợp lệ". Khi BE deploy field `identifier` xong,
  /// đổi `'email'` → `'identifier'` ở body.
  Future<ApiResponse<UserModel>> login(
      String identifier, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': identifier.trim(),
          'password': password,
        },
      );
      final payload = _extractAuthPayload(response.data);
      if (payload == null) {
        return ApiResponse(
          success: false,
          message: _extractMessage(response.data) ??
              'Phản hồi đăng nhập không đúng định dạng',
        );
      }
      final tokens = _extractTokens(payload);
      if (tokens == null || tokens.$1.isEmpty || tokens.$2.isEmpty) {
        return ApiResponse(
          success: false,
          message: 'Thiếu access/refresh token từ máy chủ',
        );
      }

      return _completeAuthSession(
        accessToken: tokens.$1,
        refreshToken: tokens.$2,
        successMessage: 'Đăng nhập thành công',
      );
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (e) {
      return ApiResponse(success: false, message: 'Đăng nhập thất bại: $e');
    }
  }

  /// Mở popup Google chỉ để lấy idToken (KHÔNG gọi `/auth/google`).
  /// Dùng cho flow accept invite — caller tự gọi `/staff/invites/accept` với
  /// idToken trả về.
  ///
  /// Returns:
  /// - `(idToken, null)` khi thành công
  /// - `(null, errorMessage)` khi fail
  /// - `(null, null)` khi user huỷ
  Future<(String?, String?)> getGoogleIdToken() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return (null, null);
      final auth = await googleUser.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        return (null, 'Không lấy được token từ Google');
      }
      return (idToken, null);
    } catch (e) {
      return (null, 'Đăng nhập Google thất bại: $e');
    }
  }

  /// Bắt đầu flow Google Sign-In. Lấy idToken + gửi cho BE.
  ///
  /// - [role] = null + user mới → BE trả `isNewUser: true` → outcome
  ///   [GoogleSignInNeedsRole]. UI push RolePickerScreen rồi gọi lại
  ///   [completeGoogleSignInWithRole] với role user chọn.
  /// - [role] có giá trị + user mới → BE tạo user role đó → [GoogleSignInSuccess]
  /// - User đã tồn tại → BE bỏ qua [role] → [GoogleSignInSuccess]
  Future<GoogleSignInOutcome> loginWithGoogle({int? role}) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const GoogleSignInCancelled();
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        return const GoogleSignInFailure('Không lấy được token từ Google');
      }

      return await _exchangeGoogleIdToken(idToken: idToken, role: role);
    } on DioException catch (e) {
      return GoogleSignInFailure(parseDioError(e));
    } catch (e) {
      return GoogleSignInFailure('Đăng nhập Google thất bại: $e');
    }
  }

  /// Apple Sign In — bắt buộc theo Apple Guideline 4.8 khi app có Google login.
  /// Trả `GoogleSignInOutcome` để dùng chung router/UI logic với Google flow.
  ///
  /// iOS native: dùng `SignInWithApple.getAppleIDCredential` (popup hệ thống).
  /// Android/Web: package fallback web flow — chưa support trong app này nên
  /// caller chỉ enable button khi `Platform.isIOS`.
  Future<GoogleSignInOutcome> loginWithApple({int? role}) async {
    try {
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        return const GoogleSignInFailure(
          'Sign In with Apple chưa sẵn sàng trên thiết bị này',
        );
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        return const GoogleSignInFailure('Không lấy được token từ Apple');
      }

      final fullName = [
        credential.givenName ?? '',
        credential.familyName ?? '',
      ].where((s) => s.isNotEmpty).join(' ').trim();

      return await _exchangeAppleIdToken(
        idToken: idToken,
        role: role,
        email: credential.email,
        name: fullName.isEmpty ? null : fullName,
        authorizationCode: credential.authorizationCode,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return const GoogleSignInCancelled();
      }
      return GoogleSignInFailure('Đăng nhập Apple thất bại: ${e.message}');
    } on DioException catch (e) {
      return GoogleSignInFailure(parseDioError(e));
    } catch (e) {
      return GoogleSignInFailure('Đăng nhập Apple thất bại: $e');
    }
  }

  /// Tương tự `completeGoogleSignInWithRole` nhưng cho Apple flow.
  /// Apple chỉ trả tên/email lần đầu user authorize → FE cache tạm để gửi lại.
  Future<GoogleSignInOutcome> completeAppleSignInWithRole({
    required String idToken,
    required int role,
    String? email,
    String? name,
  }) async {
    try {
      return await _exchangeAppleIdToken(
        idToken: idToken,
        role: role,
        email: email,
        name: name,
      );
    } on DioException catch (e) {
      return GoogleSignInFailure(parseDioError(e));
    } catch (e) {
      return GoogleSignInFailure('Hoàn tất đăng ký Apple thất bại: $e');
    }
  }

  Future<GoogleSignInOutcome> _exchangeAppleIdToken({
    required String idToken,
    int? role,
    String? email,
    String? name,
    String? authorizationCode,
  }) async {
    final response = await _dio.post(
      ApiConstants.appleLogin,
      data: {
        'idToken': idToken,
        if (role != null) 'role': role,
        if (email != null && email.isNotEmpty) 'email': email,
        if (name != null && name.isNotEmpty) 'name': name,
        if (authorizationCode != null) 'authorizationCode': authorizationCode,
        'platform': Platform.isIOS ? 'ios' : 'android',
      },
      options: Options(headers: await _antiSpamHeaders()),
    );
    final payload = _extractAuthPayload(response.data);
    if (payload == null) {
      return GoogleSignInFailure(
        _extractMessage(response.data) ??
            'Phản hồi đăng nhập Apple không đúng định dạng',
      );
    }

    if (payload['isNewUser'] == true) {
      final profileMap = payload['googleProfile'] ??
          payload['appleProfile'] ??
          {
            'email': email ?? '',
            'name': name ?? '',
            'sub': '',
          };
      if (profileMap is! Map<String, dynamic>) {
        return const GoogleSignInFailure('Phản hồi role picker thiếu profile');
      }
      // Thêm idToken vào outcome để FE gọi lại endpoint sau role picker.
      return GoogleSignInNeedsRole(
        idToken: idToken,
        profile: GoogleProfile(
          email: profileMap['email'] as String? ?? email ?? '',
          name: profileMap['name'] as String? ?? name ?? '',
          avatar: profileMap['avatar'] as String?,
          sub: profileMap['sub'] as String? ?? '',
        ),
      );
    }

    final tokens = _extractTokens(payload);
    if (tokens == null || tokens.$1.isEmpty || tokens.$2.isEmpty) {
      return const GoogleSignInFailure('Thiếu access/refresh token từ máy chủ');
    }

    final profileResult = await _completeAuthSession(
      accessToken: tokens.$1,
      refreshToken: tokens.$2,
      successMessage: '',
    );
    if (!profileResult.success || profileResult.data == null) {
      return GoogleSignInFailure(
        profileResult.message.isNotEmpty
            ? profileResult.message
            : 'Không lấy được thông tin người dùng sau đăng nhập Apple',
      );
    }

    return GoogleSignInSuccess(profileResult.data!);
  }

  /// Sau khi user chọn role trên RolePickerScreen, gọi lại `/auth/google` với
  /// idToken cũ + role. idToken có thể đã hết hạn (TTL 1h) → caller nên handle
  /// 401 bằng cách quay lại [loginWithGoogle] để lấy idToken mới.
  Future<GoogleSignInOutcome> completeGoogleSignInWithRole({
    required String idToken,
    required int role,
  }) async {
    try {
      return await _exchangeGoogleIdToken(idToken: idToken, role: role);
    } on DioException catch (e) {
      return GoogleSignInFailure(parseDioError(e));
    } catch (e) {
      return GoogleSignInFailure('Hoàn tất đăng ký thất bại: $e');
    }
  }

  Future<GoogleSignInOutcome> _exchangeGoogleIdToken({
    required String idToken,
    int? role,
  }) async {
    final response = await _dio.post(
      ApiConstants.googleLogin,
      data: {
        'idToken': idToken,
        if (role != null) 'role': role,
      },
      options: Options(headers: await _antiSpamHeaders()),
    );
    final payload = _extractAuthPayload(response.data);
    if (payload == null) {
      return GoogleSignInFailure(
        _extractMessage(response.data) ??
            'Phản hồi đăng nhập Google không đúng định dạng',
      );
    }

    // Case: BE trả role picker prompt (200 + isNewUser=true).
    if (payload['isNewUser'] == true) {
      final profileMap = payload['googleProfile'];
      if (profileMap is! Map<String, dynamic>) {
        return const GoogleSignInFailure(
            'Phản hồi role picker thiếu googleProfile');
      }
      return GoogleSignInNeedsRole(
        idToken: idToken,
        profile: GoogleProfile.fromJson(profileMap),
      );
    }

    // Case: success — có tokens, user lấy qua GET /auth/profile.
    final tokens = _extractTokens(payload);
    if (tokens == null || tokens.$1.isEmpty || tokens.$2.isEmpty) {
      return const GoogleSignInFailure('Thiếu access/refresh token từ máy chủ');
    }

    final profileResult = await _completeAuthSession(
      accessToken: tokens.$1,
      refreshToken: tokens.$2,
      successMessage: '',
    );
    if (!profileResult.success || profileResult.data == null) {
      return GoogleSignInFailure(
        profileResult.message.isNotEmpty
            ? profileResult.message
            : 'Không lấy được thông tin người dùng sau đăng nhập Google',
      );
    }

    return GoogleSignInSuccess(profileResult.data!);
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
      final rawData = response.data['data'];
      if (rawData == null) {
        return ApiResponse(
          success: false,
          message: 'Không nhận được dữ liệu từ server',
        );
      }
      final user = UserModel.fromJson(rawData as Map<String, dynamic>);
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
    } catch (_) {}
    try {
      await _dio.post(ApiConstants.logout);
    } catch (_) {}
    await SecureStorage.clear();
  }

  Future<UserModel?> getStoredUser() async {
    final json = await SecureStorage.getUserData();
    if (json == null) return null;
    try {
      return UserModel.fromJsonString(json);
    } catch (_) {
      // JSON bị corrupt → bỏ qua, buộc login lại
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await SecureStorage.getAccessToken();
    return token != null;
  }

  /// Header anti-spam cho `/auth/register` và `/auth/google`.
  /// BE tracking theo deviceId (3 account/24h/device) + IP (10/24h).
  /// Nếu lấy device ID fail → bỏ header, BE fallback IP-only.
  Future<Map<String, dynamic>> _antiSpamHeaders() async {
    final deviceId = await DeviceIdService.instance.getDeviceId();
    if (deviceId == null) return const {};
    return {'X-Device-Id': deviceId};
  }

  Map<String, dynamic>? _extractAuthPayload(dynamic body) {
    if (body is! Map<String, dynamic>) {
      return null;
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    // Một số backend trả token/user trực tiếp ở root response.
    return body;
  }

  (String, String)? _extractTokens(Map<String, dynamic> payload) {
    final access =
        (payload['accessToken'] ?? payload['access_token']) as String?;
    final refresh =
        (payload['refreshToken'] ?? payload['refresh_token']) as String?;
    if (access == null || refresh == null) {
      return null;
    }
    return (access, refresh);
  }

  /// BE auth endpoints chỉ trả tokens — user lấy qua GET /auth/profile.
  Future<ApiResponse<UserModel>> _completeAuthSession({
    required String accessToken,
    required String refreshToken,
    required String successMessage,
  }) async {
    await SecureStorage.saveAccessToken(accessToken);
    await SecureStorage.saveRefreshToken(refreshToken);

    final profile = await getProfile();
    if (profile.success && profile.data != null) {
      return ApiResponse(
        success: true,
        data: profile.data,
        message: successMessage,
      );
    }
    return ApiResponse(
      success: false,
      message: profile.message.isNotEmpty
          ? profile.message
          : 'Không lấy được thông tin người dùng từ máy chủ',
    );
  }

  String? _extractMessage(dynamic body) {
    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    return null;
  }
}
