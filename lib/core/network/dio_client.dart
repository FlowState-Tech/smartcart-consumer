import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class DioClient {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  DioClient({
    required FlutterSecureStorage secureStorage,
  })  : _secureStorage = secureStorage,
        _dio = Dio(
          BaseOptions(
            baseUrl: 'https://smartcart-api-production.up.railway.app/api/v1',
            connectTimeout: const Duration(milliseconds: 15000),
            receiveTimeout: const Duration(milliseconds: 15000),
            sendTimeout: const Duration(milliseconds: 15000),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Automatically inject bearer JWT token
          final token = await _secureStorage.read(key: 'jwt_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Handle 401 Unauthorized exceptions safely
          if (e.response?.statusCode == 401) {
            debugPrint('401 Unauthorized detected. Session expired or invalid token.');
            // Clear token to force re-authentication or refresh flow
            await _secureStorage.delete(key: 'jwt_token');
            // Depending on the architecture, you could dispatch an event to the AuthBloc here,
            // or trigger a refresh token request if refresh tokens are stored.
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
