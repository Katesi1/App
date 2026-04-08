import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../shared/providers/view_mode_provider.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isLoggedIn;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.isLoggedIn = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isLoggedIn,
    String? error,
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(AuthState()) {
    _init();
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
    } else {
      // Token hết hạn hoàn toàn, refresh thất bại → buộc đăng nhập lại
      await SecureStorage.clear();
      state = AuthState(isLoading: false);
    }
  }

  Future<String?> login(String phone, String password) async {
    final result = await _repo.login(phone, password);
    if (result.success) {
      state = AuthState(user: result.data, isLoggedIn: true);
      return null;
    } else {
      state = state.copyWith(error: result.message);
      return result.message;
    }
  }

  Future<String?> register({
    required String name,
    required String phone,
    required String password,
    required String role,
    String? email,
  }) async {
    final result = await _repo.register(
      name: name,
      phone: phone,
      password: password,
      role: role,
      email: email,
    );
    if (result.success) {
      state = AuthState(user: result.data, isLoggedIn: true);
      return null;
    } else {
      state = state.copyWith(error: result.message);
      return result.message;
    }
  }

  /// [role] chỉ cần khi đăng ký qua Google lần đầu
  Future<String?> signInWithGoogle({String? role}) async {
    final result = await _repo.loginWithGoogle(role: role);
    if (result.success) {
      state = AuthState(user: result.data, isLoggedIn: true);
      return null;
    } else {
      state = state.copyWith(error: result.message);
      return result.message;
    }
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
    await _repo.logout();
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

  UserModel? get currentUser => state.user;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

/// User đang ở chế độ khách hàng?
/// - CUSTOMER role → luôn true
/// - ADMIN/STAFF → true nếu viewMode == customer
final isCustomerModeProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  if (user.isCustomer) return true;
  // ADMIN/STAFF: xem viewMode toggle
  final viewMode = ref.watch(viewModeProvider);
  return viewMode == ViewMode.customer;
});
