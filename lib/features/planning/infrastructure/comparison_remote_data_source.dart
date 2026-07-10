import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class ComparisonRemoteDataSource {
  final DioClient _client;

  ComparisonRemoteDataSource(this._client);

  Future<List<Map<String, dynamic>>> comparePrices(int listId, {String? storeFormat}) async {
    try {
      final response = await _client.dio.get(
        '/planning/lists/$listId/compare-prices',
        queryParameters: storeFormat != null ? {'storeFormat': storeFormat} : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to compare prices');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error during comparison');
    }
  }

  Future<Map<String, dynamic>> compareBasket(int listId) async {
    try {
      final response = await _client.dio.post('/planning/lists/$listId/compare-basket');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error comparing basket');
    }
  }

  Future<List<Map<String, dynamic>>> lookupBarcode(String barcode) async {
    try {
      final response = await _client.dio.get('/planning/barcode/$barcode');
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Producto no encontrado');
    }
  }

  Future<Map<String, dynamic>> getTotalCost(int listId) async {
    try {
      final response = await _client.dio.get('/planning/lists/$listId/total-cost');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al obtener costo total');
    }
  }

  Future<List<String>> verifyStock(int listId, int storeId) async {
    try {
      final response = await _client.dio.get('/planning/lists/$listId/stores/$storeId/stock');
      final List<dynamic> data = response.data;
      return data.cast<String>();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al verificar stock');
    }
  }

  Future<Map<String, dynamic>> getSubstitute(int listId, int storeId, String sku) async {
    try {
      final response = await _client.dio.get(
        '/planning/lists/$listId/stores/$storeId/substitutes',
        queryParameters: {'sku': sku},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al obtener sustituto');
    }
  }

  Future<List<Map<String, dynamic>>> getAllSubstitutes(int listId, int storeId) async {
    try {
      final response = await _client.dio.get('/planning/lists/$listId/stores/$storeId/substitutes/all');
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al obtener sustitutos');
    }
  }
}
