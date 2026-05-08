import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import 'api_provider.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

enum AuthFailure { emailTaken, invalidCredentials, connection }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.failure,
  });

  final AuthStatus status;
  final AuthFailure? failure;

  AuthState copyWith({
    AuthStatus? status,
    AuthFailure? failure,
    bool clearFailure = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._apiService) : super(const AuthState());

  final ApiService _apiService;

  Future<void> checkAuthStatus() async {
    final isLoggedIn = await _apiService.isLoggedIn();
    state = AuthState(
      status: isLoggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearFailure: true,
    );
    try {
      await _apiService.login(email, password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        clearFailure: true,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        failure: _getFailure(e),
      );
    }
  }

  Future<void> register(String email, String password) async {
    state = state.copyWith(
      status: AuthStatus.loading,
      clearFailure: true,
    );
    try {
      await _apiService.register(email, password);
      await _apiService.login(email, password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        clearFailure: true,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        failure: _getFailure(e),
      );
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      clearFailure: true,
    );
  }

  AuthFailure _getFailure(dynamic error) {
    if (error.toString().contains('400')) {
      return AuthFailure.emailTaken;
    }
    if (error.toString().contains('401')) {
      return AuthFailure.invalidCredentials;
    }
    return AuthFailure.connection;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthNotifier(apiService);
});
