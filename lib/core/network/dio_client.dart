import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'session_events.dart';

class DioClient {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  DioClient({
    required FlutterSecureStorage secureStorage,
  })  : _secureStorage = secureStorage,
        _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
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
          if (_isAuthPath(options.path)) {
            options.headers.remove('Authorization');
          } else {
            final token = await _secureStorage.read(key: 'jwt_token');
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            final hadAuth = e.requestOptions.headers['Authorization'] != null;
            final isAuth = _isAuthPath(e.requestOptions.path);
            if (hadAuth && !isAuth) {
              debugPrint('401 Unauthorized — session expired.');
              await _clearSessionKeys();
              SessionEvents.notifySessionExpired();
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  bool _isAuthPath(String path) => path.contains('/authentication/');

  Future<void> _clearSessionKeys() async {
    await _secureStorage.delete(key: 'jwt_token');
    await _secureStorage.delete(key: 'user_email');
    await _secureStorage.delete(key: 'user_id');
    await _secureStorage.delete(key: 'user_username');
  }

  Dio get dio => _dio;
}
