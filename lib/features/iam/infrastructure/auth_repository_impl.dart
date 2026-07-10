import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/user_aggregate.dart';
import '../domain/value_objects.dart';
import 'auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final FlutterSecureStorage _secureStorage;

  AuthRepositoryImpl(this._remoteDataSource, this._secureStorage);

  @override
  Future<UserAggregate> signIn(String identifier, UserPassword password) async {
    await _clearStaleToken();

    final storedEmail = await _secureStorage.read(key: 'user_email');
    final storedUsername = await _secureStorage.read(key: 'user_username');
    final isEmail = identifier.contains('@');

    final usernameAttempts = <String>[];
    if (!isEmail) {
      usernameAttempts.add(identifier.trim());
    } else {
      if (storedEmail == identifier.trim() && storedUsername != null && storedUsername.isNotEmpty) {
        usernameAttempts.add(storedUsername);
      }
      usernameAttempts.add(identifier.split('@').first);
      usernameAttempts.add(identifier.trim());
    }

    Object? lastError;
    for (final username in usernameAttempts.toSet()) {
      if (username.isEmpty) continue;
      try {
        final response = await _remoteDataSource.signIn(
          username: username,
          password: password.value,
          email: isEmail ? identifier.trim() : storedEmail,
        );
        return _persistSession(
          response,
          fallbackEmail: isEmail ? identifier.trim() : storedEmail,
        );
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception(lastError?.toString().replaceFirst('Exception: ', '') ?? 'Credenciales inválidas');
  }

  @override
  Future<UserAggregate> signUp(UserEmail email, UserPassword password, {String? username}) async {
    await _secureStorage.deleteAll();
    final response = await _remoteDataSource.signUp(
      email.value,
      password.value,
      username: username,
    );
    return _persistSession(response, fallbackEmail: email.value);
  }

  @override
  Future<void> logout() async {
    await _secureStorage.deleteAll();
  }

  @override
  Future<void> deleteAccount() async {
    await _secureStorage.deleteAll();
  }

  @override
  Future<UserAggregate?> checkSession() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    final email = await _secureStorage.read(key: 'user_email');
    final id = await _secureStorage.read(key: 'user_id');
    final username = await _secureStorage.read(key: 'user_username');

    if (token == null || token.isEmpty || id == null || id.isEmpty) {
      return null;
    }

    final resolvedEmail = email ?? _syntheticEmail(username);
    if (resolvedEmail == null) return null;

    try {
      return UserAggregate(
        id: id,
        email: UserEmail(resolvedEmail),
        token: token,
        username: username,
      );
    } catch (_) {
      await _secureStorage.deleteAll();
      return null;
    }
  }

  Future<void> _clearStaleToken() async {
    await _secureStorage.delete(key: 'jwt_token');
  }

  Future<UserAggregate> _persistSession(
    Map<String, dynamic> response, {
    String? fallbackEmail,
  }) async {
    final token = response['token'] as String?;
    final id = response['user_id']?.toString();
    final username = response['username']?.toString();
    var email = response['email']?.toString() ?? fallbackEmail;

    if ((email == null || email.isEmpty) && username != null && username.isNotEmpty) {
      email = _syntheticEmail(username);
    }

    if (token == null || token.isEmpty || id == null || id.isEmpty || email == null || email.isEmpty) {
      throw Exception('No se pudo guardar la sesión. Intenta iniciar sesión manualmente.');
    }

    await _secureStorage.write(key: 'jwt_token', value: token);
    await _secureStorage.write(key: 'user_email', value: email);
    await _secureStorage.write(key: 'user_id', value: id);
    if (username != null && username.isNotEmpty) {
      await _secureStorage.write(key: 'user_username', value: username);
    }

    return UserAggregate(
      id: id,
      email: UserEmail(email),
      token: token,
      username: username,
    );
  }

  String? _syntheticEmail(String? username) {
    if (username == null || username.isEmpty) return null;
    final safe = username.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '');
    if (safe.isEmpty) return null;
    return '$safe@smartcart.app';
  }
}
