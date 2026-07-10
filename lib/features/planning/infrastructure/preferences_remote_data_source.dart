import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class PreferencesRemoteDataSource {
  final DioClient _client;

  PreferencesRemoteDataSource(this._client);

  Future<Map<String, dynamic>> getPreferences(int buyerId) async {
    try {
      final response = await _client.dio.get('/planning/preferences/$buyerId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al obtener preferencias');
    }
  }

  Future<Map<String, dynamic>> updatePreferences(int buyerId, Map<String, dynamic> body) async {
    try {
      final response = await _client.dio.put('/planning/preferences/$buyerId', data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al guardar preferencias');
    }
  }

  Future<Map<String, dynamic>> updatePreferredStores(int buyerId, List<int> storeIds) async {
    try {
      final response = await _client.dio.post('/planning/preferences/stores', data: {
        'buyerId': buyerId,
        'storeIds': storeIds,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al guardar tiendas favoritas');
    }
  }
}
