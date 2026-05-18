import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/services/device_id_service.dart';
import '../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

/// Google profile returned for new users — FE uses it to preview on RolePickerScreen.
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

/// Google Sign-In result. Sealed so callers can exhaustively switch.
sealed class GoogleSignInOutcome {
  const GoogleSignInOutcome();
}

/// Login/Register succeeded — tokens + user are available.
class GoogleSignInSuccess extends GoogleSignInOutcome {
  final UserModel user;
  const GoogleSignInSuccess(this.user);
}

/// New user — BE requires picking a role. UI pushes RolePickerScreen with
/// [idToken] + [profile] to call `/auth/google` again after the choice.
class GoogleSignInNeedsRole extends GoogleSignInOutcome {
  final String idToken;
  final GoogleProfile profile;
  const GoogleSignInNeedsRole({required this.idToken, required this.profile});
}

/// User cancelled the Google popup.
class GoogleSignInCancelled extends GoogleSignInOutcome {
  const GoogleSignInCancelled();
}

/// Error (network, BE reject, bad idToken, etc.).
class GoogleSignInFailure extends GoogleSignInOutcome {
  final String message;
  const GoogleSignInFailure(this.message);
}

class AuthRepository {
  final _dio = ApiClient.instance;
  final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '832659566372-25rp2ch2s7nqiho1057i1ho1g2i1ffmc.apps.googleusercontent.com',
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
      final userMap = _extractUser(payload);
      if (userMap == null) {
        return ApiResponse(
          success: false,
          message: 'Thiếu thông tin người dùng từ máy chủ',
        );
      }

      await SecureStorage.saveAccessToken(tokens.$1);
      await SecureStorage.saveRefreshToken(tokens.$2);

      final user = UserModel.fromJson(userMap);
      await SecureStorage.saveUserData(user.toJsonString());

      return ApiResponse(
          success: true, data: user, message: 'Đăng ký thành công');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (e) {
      return ApiResponse(success: false, message: 'Đăng ký thất bại: $e');
    }
  }

  /// Login with email (+ phone once BE ships the `identifier` field).
  ///
  /// WARNING: BE DTO still has `@IsEmail()` on the `email` field — phone
  /// login returns 400 "Email không hợp lệ". Once BE deploys the `identifier`
  /// field, switch the body key from `'email'` → `'identifier'`.
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
      final userMap = _extractUser(payload);
      if (userMap == null) {
        return ApiResponse(
          success: false,
          message: 'Thiếu thông tin người dùng từ máy chủ',
        );
      }

      await SecureStorage.saveAccessToken(tokens.$1);
      await SecureStorage.saveRefreshToken(tokens.$2);

      final user = UserModel.fromJson(userMap);
      await SecureStorage.saveUserData(user.toJsonString());

      return ApiResponse(
          success: true, data: user, message: 'Đăng nhập thành công');
    } on DioException catch (e) {
      return ApiResponse(success: false, message: parseDioError(e));
    } catch (e) {
      return ApiResponse(success: false, message: 'Đăng nhập thất bại: $e');
    }
  }

  /// Open the Google popup just to fetch an idToken (does NOT call
  /// `/auth/google`). Used for the accept-invite flow — caller invokes
  /// `/staff/invites/accept` with the returned idToken.
  ///
  /// Returns:
  /// - `(idToken, null)` on success
  /// - `(null, errorMessage)` on failure
  /// - `(null, null)` when the user cancels
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

  /// Start the Google Sign-In flow. Fetch idToken and exchange with BE.
  ///
  /// - [role] = null + new user → BE returns `isNewUser: true` → outcome
  ///   [GoogleSignInNeedsRole]. UI pushes RolePickerScreen and then calls
  ///   [completeGoogleSignInWithRole] with the chosen role.
  /// - [role] provided + new user → BE creates the user with that role →
  ///   [GoogleSignInSuccess]
  /// - Existing user → BE ignores [role] → [GoogleSignInSuccess]
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

  /// Sign In with Apple — required by Apple Guideline 4.8 when the app
  /// supports Google login. Returns `GoogleSignInOutcome` to share router/UI
  /// logic with the Google flow.
  ///
  /// Uses `SignInWithApple.getAppleIDCredential` (iOS system popup).
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
        return const GoogleSignInFailure(
            'Không lấy được token từ Apple');
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

  /// Like `completeGoogleSignInWithRole` but for the Apple flow.
  /// Apple only returns name/email on the first authorization → FE caches
  /// them so they can be re-sent.
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
        'platform': 'ios',
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
        return const GoogleSignInFailure(
            'Phản hồi role picker thiếu profile');
      }
      // Include idToken in the outcome so FE can replay the endpoint after the role picker.
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
      return const GoogleSignInFailure(
          'Thiếu access/refresh token từ máy chủ');
    }
    final userMap = _extractUser(payload);
    if (userMap == null) {
      return const GoogleSignInFailure(
          'Thiếu thông tin người dùng từ máy chủ');
    }

    await SecureStorage.saveAccessToken(tokens.$1);
    await SecureStorage.saveRefreshToken(tokens.$2);

    final user = UserModel.fromJson(userMap);
    await SecureStorage.saveUserData(user.toJsonString());

    return GoogleSignInSuccess(user);
  }

  /// After the user picks a role on RolePickerScreen, call `/auth/google`
  /// again with the previous idToken + role. The idToken may have expired
  /// (TTL 1h) → caller should handle 401 by falling back to [loginWithGoogle]
  /// to fetch a fresh one.
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

    // Case: BE returns the role picker prompt (200 + isNewUser=true).
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

    // Case: success — tokens + user present.
    final tokens = _extractTokens(payload);
    if (tokens == null || tokens.$1.isEmpty || tokens.$2.isEmpty) {
      return const GoogleSignInFailure(
          'Thiếu access/refresh token từ máy chủ');
    }
    final userMap = _extractUser(payload);
    if (userMap == null) {
      return const GoogleSignInFailure(
          'Thiếu thông tin người dùng từ máy chủ');
    }

    await SecureStorage.saveAccessToken(tokens.$1);
    await SecureStorage.saveRefreshToken(tokens.$2);

    final user = UserModel.fromJson(userMap);
    await SecureStorage.saveUserData(user.toJsonString());

    return GoogleSignInSuccess(user);
  }

  /// GET /auth/profile — refresh the user after app open / session renewal.
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
    } catch (_) {}
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

  /// Anti-spam headers for `/auth/register` and `/auth/google`.
  /// BE tracks per deviceId (3 accounts/24h/device) + IP (10/24h).
  /// If fetching device ID fails → drop the header; BE falls back to IP-only.
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
    // Some backends return token/user directly at the root of the response.
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

  Map<String, dynamic>? _extractUser(Map<String, dynamic> payload) {
    final user = payload['user'];
    if (user is Map<String, dynamic>) {
      return user;
    }
    return null;
  }

  String? _extractMessage(dynamic body) {
    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    return null;
  }
}
