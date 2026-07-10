import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/injection_container.dart';
import '../domain/auth_repository.dart';
import '../domain/value_objects.dart';
import 'auth_state.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return sl<AuthNotifier>();
});

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

  Future<void> signIn(String identifier, String passwordStr) async {
    state = AuthLoading();
    try {
      final password = UserPassword(passwordStr);
      final user = await _repository.signIn(identifier.trim(), password);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthUnauthenticated();
      rethrow;
    }
  }

  Future<void> signUp(String emailStr, String passwordStr, {String? fullName}) async {
    state = AuthLoading();
    try {
      final email = UserEmail(emailStr.trim());
      final password = UserPassword(passwordStr);
      final user = await _repository.signUp(email, password, username: fullName?.trim());
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthUnauthenticated();
      rethrow;
    }
  }

  Future<void> logout() async {
    state = AuthLoading();
    await _repository.logout();
    state = AuthUnauthenticated();
  }

  void forceLogout() {
    state = AuthUnauthenticated();
  }

  Future<void> deleteAccount() async {
    if (state is AuthAuthenticated) {
      state = AuthLoading();
      try {
        await _repository.deleteAccount();
        state = AuthUnauthenticated();
      } catch (e) {
        state = AuthUnauthenticated();
        rethrow;
      }
    }
  }

  static String cleanError(Object error) {
    if (error is ArgumentError) {
      final msg = error.message?.toString() ?? '';
      if (msg.toLowerCase().contains('email')) {
        return 'Ingresa un correo electrónico válido';
      }
      if (msg.toLowerCase().contains('password')) {
        return 'La contraseña debe tener al menos 8 caracteres';
      }
    }
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.isEmpty || raw == 'null') return 'Ocurrió un error. Intenta de nuevo.';
    return raw;
  }
}
