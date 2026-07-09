import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/auth_repository.dart';
import '../domain/value_objects.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthInitial()) {
    checkSession();
  }

  Future<void> checkSession() async {
    state = AuthLoading();
    final user = await _repository.checkSession();
    if (user != null) {
      state = AuthAuthenticated(user);
    } else {
      state = AuthUnauthenticated();
    }
  }

  Future<void> signIn(String emailStr, String passwordStr) async {
    state = AuthLoading();
    try {
      final email = UserEmail(emailStr);
      final password = UserPassword(passwordStr);
      final user = await _repository.signIn(email, password);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> signUp(String emailStr, String passwordStr) async {
    state = AuthLoading();
    try {
      final email = UserEmail(emailStr);
      final password = UserPassword(passwordStr);
      final user = await _repository.signUp(email, password);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    state = AuthLoading();
    await _repository.logout();
    state = AuthUnauthenticated();
  }

  Future<void> deleteAccount() async {
    if (state is AuthAuthenticated) {
      final user = (state as AuthAuthenticated).user;
      state = AuthLoading();
      try {
        await _repository.deleteAccount(user.token);
        state = AuthUnauthenticated();
      } catch (e) {
        state = AuthError(e.toString());
      }
    }
  }
}
