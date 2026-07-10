import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class NotificationsRemoteDataSource {
  final DioClient _client;

  NotificationsRemoteDataSource(this._client);

  Future<Map<String, dynamic>> getPreferences(int userId) async {
    try {
      final response = await _client.dio.get('/notifications/preferences/$userId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al obtener notificaciones');
    }
  }

  Future<Map<String, dynamic>> updatePreferences(Map<String, dynamic> body) async {
    try {
      final response = await _client.dio.post('/notifications/preferences', data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al guardar notificaciones');
    }
  }

  Future<Map<String, dynamic>> getHistory(int userId, {int page = 0, int size = 20}) async {
    try {
      final response = await _client.dio.get(
        '/notifications/history/$userId',
        queryParameters: {'page': page, 'size': size},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al obtener historial');
    }
  }
}
