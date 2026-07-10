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
          email: isEmail ? identifier.trim() : null,
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
    if (token == null || token.isEmpty) return null;

    try {
      final me = await _remoteDataSource.getCurrentUser();
      final response = {
        'token': token,
        'user_id': me['id']?.toString() ?? me['userId']?.toString(),
        'username': me['username']?.toString(),
        'email': me['email']?.toString(),
      };
      return _persistSession(
        response,
        fallbackEmail: await _secureStorage.read(key: 'user_email'),
      );
    } catch (_) {
      await _secureStorage.deleteAll();
      return null;
    }
  }

  Future<UserAggregate> _persistSession(
    Map<String, dynamic> response, {
    String? fallbackEmail,
  }) async {
    final token = response['token'] as String?;
    final id = response['user_id']?.toString();
    final username = response['username']?.toString();
    final email = response['email']?.toString() ?? fallbackEmail;

    if (token == null || token.isEmpty || id == null || id.isEmpty || email == null || email.isEmpty) {
      throw Exception('Respuesta de autenticación incompleta');
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
}
