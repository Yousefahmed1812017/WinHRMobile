import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

/// Provides a singleton [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Tracks the authentication state.
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.read(authRepositoryProvider));
});

/// Auth status enum.
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

/// Auth state including user session data.
class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final UserData? user;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    UserData? user,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      user: clearUser ? null : (user ?? this.user),
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthStateNotifier(this._repo) : super(const AuthState());

  Future<void> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final userData = await _repo.login(username, password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: userData,
      );
    } catch (e) {
      String errorMsg = 'فشل تسجيل الدخول';
      final errStr = e.toString();
      if (errStr.contains('Exception: ')) {
        errorMsg = errStr.replaceFirst('Exception: ', '');
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: errorMsg,
      );
    }
  }

  Future<void> checkAuth() async {
    final hasToken = await _repo.hasToken();
    if (hasToken) {
      final userData = await _repo.getUserData();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: userData,
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      clearUser: true,
    );
  }
}
