import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class ShoppingListRemoteDataSource {
  final DioClient _client;

  ShoppingListRemoteDataSource(this._client);

  Future<Map<String, dynamic>> createList(int buyerId, String name) async {
    try {
      final response = await _client.dio.post('/planning/lists', data: {
        'buyerId': buyerId,
        'name': name,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error creating list');
    }
  }

  Future<Map<String, dynamic>> getList(int listId) async {
    try {
      final response = await _client.dio.get('/planning/lists/$listId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error fetching list');
    }
  }

  Future<List<dynamic>> getListsByBuyer(int buyerId) async {
    try {
      final response = await _client.dio.get('/planning/buyers/$buyerId/lists');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error fetching lists');
    }
  }

  Future<Map<String, dynamic>> addItem(int listId, Map<String, dynamic> item) async {
    try {
      final response = await _client.dio.post('/planning/lists/$listId/items', data: item);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error adding item');
    }
  }

  Future<Map<String, dynamic>> removeItem(int listId, int itemId) async {
    try {
      final response = await _client.dio.delete('/planning/lists/$listId/items/$itemId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error removing item');
    }
  }

  Future<Map<String, dynamic>> applyFamilyBasket(int buyerId, int listId) async {
    try {
      final response = await _client.dio.post('/planning/buyers/$buyerId/lists/$listId/apply-family-basket');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error applying family basket');
    }
  }
}
