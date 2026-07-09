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
  Future<UserAggregate> signIn(UserEmail email, UserPassword password) async {
    final response = await _remoteDataSource.signIn(email.value, password.value);
    final token = response['token'];
    final id = response['user_id'];
    
    await _secureStorage.write(key: 'jwt_token', value: token);
    await _secureStorage.write(key: 'user_email', value: email.value);
    await _secureStorage.write(key: 'user_id', value: id);

    return UserAggregate(id: id, email: email, token: token);
  }

  @override
  Future<UserAggregate> signUp(UserEmail email, UserPassword password) async {
    final response = await _remoteDataSource.signUp(email.value, password.value);
    final token = response['token'];
    final id = response['user_id'];
    
    await _secureStorage.write(key: 'jwt_token', value: token);
    await _secureStorage.write(key: 'user_email', value: email.value);
    await _secureStorage.write(key: 'user_id', value: id);

    return UserAggregate(id: id, email: email, token: token);
  }

  @override
  Future<void> logout() async {
    await _secureStorage.deleteAll();
  }

  @override
  Future<void> deleteAccount(String token) async {
    await _remoteDataSource.deleteAccount();
    await _secureStorage.deleteAll();
  }

  @override
  Future<UserAggregate?> checkSession() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    final email = await _secureStorage.read(key: 'user_email');
    final id = await _secureStorage.read(key: 'user_id');

    if (token != null && email != null && id != null) {
      try {
        return UserAggregate(id: id, email: UserEmail(email), token: token);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
