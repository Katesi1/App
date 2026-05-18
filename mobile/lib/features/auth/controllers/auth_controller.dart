import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/monitoring/crash_reporter.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../bookings/controllers/booking_controller.dart';
import '../../calendar/controllers/calendar_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../properties/controllers/property_controller.dart';
import '../../rooms/controllers/room_controller.dart';

export '../../../data/repositories/auth_repository.dart'
    show
        GoogleSignInOutcome,
        GoogleSignInSuccess,
        GoogleSignInNeedsRole,
        GoogleSignInCancelled,
        GoogleSignInFailure,
        GoogleProfile;

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isLoggedIn;
  final String? error;

  /// Đặt = true khi server từ chối token (refresh fail). Login screen detect
  /// transition false→true qua `ref.listen` → show snackbar + gọi
  /// `consumeForceLogoutFlag()` để reset.
  final bool forceLoggedOut;

  AuthState({
    this.user,
    this.isLoading = false,
    this.isLoggedIn = false,
    this.error,
    this.forceLoggedOut = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isLoggedIn,
    String? error,
    bool? forceLoggedOut,
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        error: error,
        forceLoggedOut: forceLoggedOut ?? this.forceLoggedOut,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final Ref _ref;

  StreamSubscription<void>? _forceLogoutSub;

  AuthNotifier(this._repo, this._ref) : super(AuthState()) {
    _init();
    // Lắng nghe force-logout từ ApiClient (refresh token fail).
    // SecureStorage đã được clear bởi interceptor trước khi event fire — chỉ
    // cần reset state để router redirect /login + flag để login screen
    // show snackbar.
    _forceLogoutSub = ApiClient.onForceLogout.listen((_) {
      if (!mounted) return;
      state = AuthState(forceLoggedOut: true);
    });
  }

  @override
  void dispose() {
    _forceLogoutSub?.cancel();
    super.dispose();
  }

  /// Login screen gọi sau khi đã hiển thị snackbar — clear flag để không
  /// trigger lần 2 khi user back ra rồi vào lại.
  void consumeForceLogoutFlag() {
    if (state.forceLoggedOut) {
      state = state.copyWith(forceLoggedOut: false);
    }
  }

  /// Gọi sau khi user đã authenticated (login/register/google/accept invite/
  /// app restart với token còn valid). Register FCM token với BE + set
  /// Crashlytics user ID — fire & forget, không block UI.
  void _onAuthenticated() {
    unawaited(PushNotificationService.instance.registerForUser());
    final userId = state.user?.id;
    if (userId != null) {
      unawaited(CrashReporter.setUserId(userId));
    }
  }

  /// Invalidate tất cả data providers sau login/register
  /// Để screen watch lại → tự re-fetch với token mới
  void _invalidateDataProviders() {
    _ref.invalidate(dashboardStatsProvider);
    _ref.invalidate(roomListProvider);
    _ref.invalidate(allRoomsProvider);
    _ref.invalidate(homestayListProvider);
    _ref.invalidate(bookingListProvider);
    _ref.invalidate(calendarGridProvider);
    // Reset banner "STAFF chưa được gán owner" — hiện lại 1 lần / phiên login
    _ref.invalidate(unassignedBannerDismissedProvider);
    // staffListProvider không cần invalidate — nó watch currentUserProvider
    // nên tự re-fetch khi user thay đổi
  }

  Future<void> _init() async {
    // Giữ isLoading = true cho đến khi verify xong — GoRouter không redirect sớm
    final user = await _repo.getStoredUser();
    final isLoggedIn = await _repo.isLoggedIn();

    if (!isLoggedIn) {
      state = AuthState(isLoading: false);
      return;
    }

    // Hiển thị user đã lưu ngay lập tức (UX tốt hơn), nhưng giữ isLoading
    state = AuthState(user: user, isLoggedIn: true, isLoading: true);

    // Verify token bằng cách gọi profile — interceptor tự refresh nếu cần
    final fresh = await _repo.getProfile();
    if (fresh.success && fresh.data != null) {
      // Token hợp lệ (hoặc đã refresh thành công)
      state = AuthState(user: fresh.data, isLoggedIn: true, isLoading: false);
      _onAuthenticated();
    } else {
      // Token hết hạn hoàn toàn, refresh thất bại → buộc đăng nhập lại
      await SecureStorage.clear();
      state = AuthState(isLoading: false);
    }
  }

  Future<String?> login(String identifier, String password) async {
    final result = await _repo.login(identifier, password);
    if (result.success) {
      state = AuthState(user: result.data, isLoggedIn: true);
      _invalidateDataProviders();
      _onAuthenticated();
      return null;
    } else {
      state = state.copyWith(error: result.message);
      return result.message;
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required int role,
    String? phone,
  }) async {
    final result = await _repo.register(
      name: name,
      email: email,
      password: password,
      role: role,
      phone: phone,
    );
    if (result.success) {
      state = AuthState(user: result.data, isLoggedIn: true);
      _invalidateDataProviders();
      _onAuthenticated();
      return null;
    } else {
      state = state.copyWith(error: result.message);
      return result.message;
    }
  }

  /// Bắt đầu Google Sign-In. Trả `GoogleSignInOutcome` để UI điều hướng:
  /// - [GoogleSignInSuccess] → đã login, vào dashboard
  /// - [GoogleSignInNeedsRole] → push RolePickerScreen
  /// - [GoogleSignInCancelled] → user đóng pop-up
  /// - [GoogleSignInFailure] → show snackbar lỗi
  ///
  /// [role] chỉ cần khi user đã chủ động chọn từ Register screen (OWNER).
  Future<GoogleSignInOutcome> signInWithGoogle({int? role}) async {
    final outcome = await _repo.loginWithGoogle(role: role);
    return _handleGoogleOutcome(outcome);
  }

  /// Gọi sau khi user chọn role trên RolePickerScreen.
  Future<GoogleSignInOutcome> completeGoogleSignInWithRole({
    required String idToken,
    required int role,
  }) async {
    final outcome = await _repo.completeGoogleSignInWithRole(
      idToken: idToken,
      role: role,
    );
    return _handleGoogleOutcome(outcome);
  }

  /// Sign In with Apple — bắt buộc theo App Store Guideline 4.8.
  Future<GoogleSignInOutcome> signInWithApple({int? role}) async {
    final outcome = await _repo.loginWithApple(role: role);
    return _handleGoogleOutcome(outcome);
  }

  Future<GoogleSignInOutcome> completeAppleSignInWithRole({
    required String idToken,
    required int role,
    String? email,
    String? name,
  }) async {
    final outcome = await _repo.completeAppleSignInWithRole(
      idToken: idToken,
      role: role,
      email: email,
      name: name,
    );
    return _handleGoogleOutcome(outcome);
  }

  /// Mở popup Google chỉ để lấy idToken (cho accept invite flow).
  Future<(String?, String?)> getGoogleIdToken() => _repo.getGoogleIdToken();

  GoogleSignInOutcome _handleGoogleOutcome(GoogleSignInOutcome outcome) {
    switch (outcome) {
      case GoogleSignInSuccess(:final user):
        state = AuthState(user: user, isLoggedIn: true);
        _invalidateDataProviders();
        _onAuthenticated();
      case GoogleSignInFailure(:final message):
        state = state.copyWith(error: message);
      case GoogleSignInNeedsRole():
      case GoogleSignInCancelled():
        // Không update state — UI tự xử lý navigation/snackbar.
        break;
    }
    return outcome;
  }

  Future<(bool, String)> forgotPassword(String identifier) async {
    final result = await _repo.forgotPassword(identifier);
    return (result.success, result.message);
  }

  Future<(bool, String)> resetPassword(String token, String newPassword) async {
    final result = await _repo.resetPassword(token, newPassword);
    return (result.success, result.message);
  }

  Future<(bool, String)> changePassword(
      String currentPassword, String newPassword) async {
    final result = await _repo.changePassword(currentPassword, newPassword);
    return (result.success, result.message);
  }

  Future<(bool, String)> updateProfile(Map<String, dynamic> data) async {
    final userId = state.user?.id;
    if (userId == null) return (false, 'Không tìm thấy người dùng');
    final result = await _repo.updateProfile(userId, data);
    if (result.success && result.data != null) {
      state = state.copyWith(user: result.data);
    }
    return (result.success, result.message);
  }

  Future<void> logout() async {
    // Unregister FCM trước khi clear tokens — endpoint /devices cần Bearer
    // token. Best-effort: nếu fail vẫn tiếp tục logout.
    await PushNotificationService.instance.unregisterForUser();
    await _repo.logout();
    await CrashReporter.setUserId(null);
    state = AuthState();
  }

  /// Gọi GET /auth/profile và cập nhật state + bộ nhớ cục bộ.
  Future<(bool success, String message)> refreshProfile() async {
    final result = await _repo.getProfile();
    if (result.success && result.data != null) {
      state = state.copyWith(user: result.data);
      return (true, '');
    }
    return (false, result.message);
  }

  /// Cập nhật user trong state (đã lưu [SecureStorage] ở repo nếu cần).
  void replaceUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  /// Set authenticated state khi flow ngoài auth_controller đã tự lưu tokens
  /// (vd accept invite). Gọi xong router sẽ redirect tự động.
  void applyExternalLogin(UserModel user) {
    state = AuthState(user: user, isLoggedIn: true);
    _invalidateDataProviders();
    _onAuthenticated();
  }

  UserModel? get currentUser => state.user;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider), ref);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});
