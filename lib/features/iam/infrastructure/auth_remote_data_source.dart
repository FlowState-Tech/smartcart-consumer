import '../../../core/network/dio_client.dart';
import 'package:dio/dio.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> signIn(String email, String password);
  Future<Map<String, dynamic>> signUp(String email, String password);
  Future<void> deleteAccount();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final response = await _client.dio.post('/authentication/sign-in', data: {
        'username': email,
        'password': password,
      });
      return {
        'token': response.data['token'],
        'user_id': response.data['id']?.toString() ?? response.data['username'],
      };
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al iniciar sesión');
    }
  }

  @override
  Future<Map<String, dynamic>> signUp(String email, String password) async {
    try {
      final response = await _client.dio.post('/authentication/sign-up', data: {
        'username': email,
        'password': password,
        'roles': ['ROLE_CUSTOMER'],
      });
      
      // Some APIs don't return a token on sign-up, so we sign in automatically
      return await signIn(email, password);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al registrarse');
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _client.dio.delete('/auth/account');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete account');
    }
  }
}
