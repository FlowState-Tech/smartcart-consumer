import '../../../core/network/dio_client.dart';
import 'package:dio/dio.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> signIn({
    required String username,
    required String password,
    String? email,
  });

  Future<Map<String, dynamic>> signUp(String email, String password, {String? username});

  Future<Map<String, dynamic>> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<Map<String, dynamic>> signIn({
    required String username,
    required String password,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{
        'username': username,
        'password': password,
      };
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      }

      final response = await _client.dio.post('/authentication/sign-in', data: body);
      return _parseAuthResponse(response.data as Map<String, dynamic>, fallbackUsername: username);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al iniciar sesión');
    }
  }

  @override
  Future<Map<String, dynamic>> signUp(String email, String password, {String? username}) async {
    final resolvedUsername = username ?? email.split('@').first;
    try {
      await _client.dio.post('/authentication/sign-up', data: {
        'username': resolvedUsername,
        'email': email,
        'password': password,
        'roleId': 2,
        'roles': ['ROLE_CUSTOMER'],
      });
      return signIn(username: resolvedUsername, email: email, password: password);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al registrarse');
    }
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _client.dio.get('/users/me');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Sesión inválida');
    }
  }

  Map<String, dynamic> _parseAuthResponse(
    Map<String, dynamic> data, {
    required String fallbackUsername,
  }) {
    final id = data['id']?.toString() ??
        data['user_id']?.toString() ??
        data['userId']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('El servidor no devolvió un ID de usuario válido');
    }

    return {
      'token': data['token'],
      'user_id': id,
      'username': data['username']?.toString() ?? fallbackUsername,
      'email': data['email']?.toString(),
    };
  }
}
