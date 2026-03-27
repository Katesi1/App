import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    state = state.copyWith(isLoading: true);
    final user = await _repo.getStoredUser();
    final isLoggedIn = await _repo.isLoggedIn();
    state = AuthState(user: user, isLoggedIn: isLoggedIn);
    FlutterNativeSplash.remove();
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

  Future<(bool, String)> resetPassword(
      String token, String newPassword) async {
    final result = await _repo.resetPassword(token, newPassword);
    return (result.success, result.message);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = AuthState();
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
