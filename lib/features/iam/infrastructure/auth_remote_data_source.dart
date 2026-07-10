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
      throw Exception(_message(e, 'Usuario o contraseña incorrectos'));
    }
  }

  @override
  Future<Map<String, dynamic>> signUp(String email, String password, {String? username}) async {
    final resolvedUsername = _normalizeUsername(username ?? email.split('@').first);
    try {
      await _client.dio.post('/authentication/sign-up', data: {
        'username': resolvedUsername,
        'email': email.trim(),
        'password': password,
        'roleId': 2,
        'roles': ['ROLE_CUSTOMER'],
      });
    } on DioException catch (e) {
      throw Exception(_message(e, 'No se pudo crear la cuenta'));
    }

    try {
      return await signIn(username: resolvedUsername, email: email.trim(), password: password);
    } on DioException catch (e) {
      throw Exception(
        'Cuenta creada pero no se pudo iniciar sesión. Inicia con usuario "$resolvedUsername".',
      );
    } catch (e) {
      throw Exception(
        'Cuenta creada. Inicia sesión con usuario "$resolvedUsername" y tu contraseña.',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _client.dio.get('/users/me');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_message(e, 'Sesión inválida'));
    }
  }

  String _normalizeUsername(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) throw Exception('El nombre de usuario no puede estar vacío');
    return trimmed.replaceAll(RegExp(r'\s+'), '_');
  }

  Map<String, dynamic> _parseAuthResponse(
    Map<String, dynamic> data, {
    required String fallbackUsername,
  }) {
    final id = data['id']?.toString() ??
        data['user_id']?.toString() ??
        data['userId']?.toString();
    final token = data['token']?.toString();

    if (id == null || id.isEmpty || token == null || token.isEmpty) {
      throw Exception('El servidor no devolvió credenciales válidas');
    }

    return {
      'token': token,
      'user_id': id,
      'username': data['username']?.toString() ?? fallbackUsername,
      'email': data['email']?.toString(),
    };
  }

  String _message(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (e.response?.statusCode == 401) return 'Usuario o contraseña incorrectos';
    if (e.response?.statusCode == 409) return 'Ya existe una cuenta con ese usuario o correo';
    return fallback;
  }
}
