import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

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
  }

  Future<String?> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repo.login(phone, password);
    if (result.success) {
      state = AuthState(user: result.data, isLoggedIn: true);
      return null;
    } else {
      state = state.copyWith(isLoading: false, error: result.message);
      return result.message;
    }
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
