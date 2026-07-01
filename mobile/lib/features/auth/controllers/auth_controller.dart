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

  /// Set to true when the server rejects the token (refresh failed). The login
  /// screen detects the false→true transition via `ref.listen` → shows a
  /// snackbar + calls `consumeForceLogoutFlag()` to reset.
  final bool forceLoggedOut;

  /// Thông báo kèm theo [forceLoggedOut] — khác nhau giữa "hết phiên" và "bị đá
  /// do đăng nhập thiết bị khác" (v1.19). Login screen hiển thị message này.
  final String? forceLogoutMessage;

  /// Set to true when refreshProfile() detects that a pending deletion was
  /// auto-cancelled by the server (deletionScheduledAt was non-null, now null).
  /// Dashboard listens via ref.listen and shows a toast, then calls
  /// consumeRestoredNotice() to reset.
  final bool autoRestoredNotice;

  AuthState({
    this.user,
    this.isLoading = false,
    this.isLoggedIn = false,
    this.error,
    this.forceLoggedOut = false,
    this.forceLogoutMessage,
    this.autoRestoredNotice = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isLoggedIn,
    String? error,
    bool? forceLoggedOut,
    String? forceLogoutMessage,
    bool? autoRestoredNotice,
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        error: error,
        forceLoggedOut: forceLoggedOut ?? this.forceLoggedOut,
        forceLogoutMessage: forceLogoutMessage ?? this.forceLogoutMessage,
        autoRestoredNotice: autoRestoredNotice ?? this.autoRestoredNotice,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final Ref _ref;

  StreamSubscription<ForceLogoutReason>? _forceLogoutSub;

  AuthNotifier(this._repo, this._ref) : super(AuthState()) {
    _init();
    // Listen for force-logout from ApiClient (refresh token failed).
    // SecureStorage has already been cleared by the interceptor before this
    // event fires — we just need to reset state so the router redirects to
    // /login + raise the flag so the login screen shows a snackbar.
    _forceLogoutSub = ApiClient.onForceLogout.listen((reason) {
      if (!mounted) return;
      state = AuthState(
        forceLoggedOut: true,
        forceLogoutMessage: switch (reason) {
          ForceLogoutReason.sessionKicked =>
            'Tài khoản đã đăng nhập ở thiết bị khác. Vui lòng đăng nhập lại.',
          ForceLogoutReason.sessionExpired =>
            'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        },
      );
    });
  }

  @override
  void dispose() {
    _forceLogoutSub?.cancel();
    super.dispose();
  }

  /// The login screen calls this after showing its snackbar — clears the flag
  /// so it doesn't fire a second time if the user navigates back in.
  void consumeForceLogoutFlag() {
    if (state.forceLoggedOut) {
      state = state.copyWith(forceLoggedOut: false);
    }
  }

  /// Called after the user is authenticated (login/register/google/accept
  /// invite/app restart with a still-valid token). Registers the FCM token
  /// with BE + sets the Crashlytics user ID — fire-and-forget, doesn't block UI.
  void _onAuthenticated() {
    unawaited(PushNotificationService.instance.registerForUser());
    final userId = state.user?.id;
    if (userId != null) {
      unawaited(CrashReporter.setUserId(userId));
    }
  }

  /// Invalidate all data providers after login/register so screens watching
  /// them re-fetch with the new token.
  void _invalidateDataProviders() {
    _ref.invalidate(dashboardStatsProvider);
    _ref.invalidate(roomListProvider);
    _ref.invalidate(allRoomsProvider);
    _ref.invalidate(homestayListProvider);
    _ref.invalidate(bookingListProvider);
    _ref.invalidate(calendarGridProvider);
    // Reset the "SALE not yet assigned to an owner" banner — show it once per
    // login session.
    _ref.invalidate(unassignedBannerDismissedProvider);
    // staffListProvider doesn't need invalidation — it watches
    // currentUserProvider and re-fetches automatically when the user changes.
  }

  Future<void> _init() async {
    // Keep isLoading = true until verify completes so GoRouter doesn't redirect early.
    final user = await _repo.getStoredUser();
    final isLoggedIn = await _repo.isLoggedIn();

    if (!isLoggedIn) {
      state = AuthState(isLoading: false);
      return;
    }

    // Show the stored user immediately (better UX) but keep isLoading.
    state = AuthState(user: user, isLoggedIn: true, isLoading: true);

    // Verify the token by hitting /profile — interceptor auto-refreshes if needed.
    final fresh = await _repo.getProfile();
    if (fresh.success && fresh.data != null) {
      // Token valid (or refresh succeeded).
      state = AuthState(user: fresh.data, isLoggedIn: true, isLoading: false);
      _onAuthenticated();
    } else {
      // Token fully expired and refresh failed → force re-login.
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
      // Tài khoản đã được tạo nhưng KHÔNG auto-login — user phải đăng nhập
      // lại thủ công để xác minh mật khẩu. Clear tokens mà repo vừa lưu.
      await SecureStorage.clear();
      state = AuthState();
      return null;
    } else {
      state = state.copyWith(error: result.message);
      return result.message;
    }
  }

  /// Start Google Sign-In. Returns a `GoogleSignInOutcome` for the UI to route:
  /// - [GoogleSignInSuccess] → logged in, go to dashboard
  /// - [GoogleSignInNeedsRole] → push RolePickerScreen
  /// - [GoogleSignInCancelled] → user closed the popup
  /// - [GoogleSignInFailure] → show error snackbar
  ///
  /// [role] is only needed when the user has already picked one on the Register
  /// screen (OWNER).
  Future<GoogleSignInOutcome> signInWithGoogle({int? role}) async {
    final outcome = await _repo.loginWithGoogle(role: role);
    return _handleGoogleOutcome(outcome);
  }

  /// Called after the user picks a role on RolePickerScreen.
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

  /// Sign In with Apple — required by App Store Guideline 4.8.
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

  /// Open the Google popup just to fetch an idToken (for the accept-invite flow).
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
        // Don't update state — UI handles navigation/snackbar itself.
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
    // Unregister FCM before clearing tokens — /devices endpoint needs Bearer
    // token. Best-effort: still continue logout on failure.
    await PushNotificationService.instance.unregisterForUser();
    await _repo.logout();
    // Đăng xuất chủ động → xoá credentials đã lưu để màn login không tự
    // điền lại email/mật khẩu của tài khoản vừa thoát (remember-me chỉ phục
    // vụ trường hợp token hết hạn, không phải logout thủ công).
    await SecureStorage.clearCredentials();
    await CrashReporter.setUserId(null);
    state = AuthState();
  }

  /// Calls GET /auth/profile and updates state + local storage.
  /// Detects auto-restore: if account had pending deletion before and it's
  /// cleared now (BE auto-cancelled on login), sets autoRestoredNotice=true.
  Future<(bool success, String message)> refreshProfile() async {
    final hadPendingDeletion = state.user?.isPendingDeletion ?? false;
    final result = await _repo.getProfile();
    if (result.success && result.data != null) {
      final nowPending = result.data!.isPendingDeletion;
      state = state.copyWith(
        user: result.data,
        autoRestoredNotice: hadPendingDeletion && !nowPending,
      );
      return (true, '');
    }
    return (false, result.message);
  }

  /// Consume the auto-restore toast flag after the UI has shown it.
  void consumeRestoredNotice() {
    if (state.autoRestoredNotice) {
      state = state.copyWith(autoRestoredNotice: false);
    }
  }

  /// Update the user in state (caller is responsible for SecureStorage persistence in the repo).
  void replaceUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  /// Set authenticated state when a flow outside auth_controller already saved
  /// the tokens (e.g. accept invite). After calling, the router auto-redirects.
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
