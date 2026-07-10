import 'package:dio/dio.dart';
import '../../../core/network/api_response_utils.dart';
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
      final map = _normalizeList(response.data);
      if (map['id'] == null && map['listId'] == null && response.data is Map) {
        final raw = Map<String, dynamic>.from(response.data as Map);
        map['id'] = raw['id'] ?? raw['listId'] ?? raw['shoppingListId'];
      }
      return map;
    } on DioException catch (e) {
      throw Exception(_message(e, 'Error al crear la canasta'));
    }
  }

  Future<Map<String, dynamic>> getList(int listId) async {
    try {
      final response = await _client.dio.get('/planning/lists/$listId');
      return _normalizeList(response.data);
    } on DioException catch (e) {
      throw Exception(_message(e, 'Error al cargar la canasta'));
    }
  }

  /// Ensures callers always receive a list payload with an `items` array.
  Future<Map<String, dynamic>> resolveListAfterMutation(int listId, dynamic responseData) async {
    final normalized = _normalizeList(responseData);
    if (normalized['items'] is List) return normalized;
    return getList(listId);
  }

  Map<String, dynamic> _normalizeList(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['items'] is List) return map;
      if (map.containsKey('sku') || map.containsKey('productName')) {
        return {
          'id': map['listId'] ?? map['shoppingListId'],
          'items': [map],
        };
      }
    }
    if (data is List) {
      return {'items': ApiResponseUtils.asListOfMaps(data)};
    }
    return {'items': <dynamic>[]};
  }

  Future<List<Map<String, dynamic>>> getListsByBuyer(int buyerId) async {
    try {
      final response = await _client.dio.get('/planning/buyers/$buyerId/lists');
      return _asListOfMaps(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      throw Exception(_message(e, 'Error al obtener canastas'));
    }
  }

  Future<Map<String, dynamic>> addItem(int listId, Map<String, dynamic> item) async {
    try {
      final response = await _client.dio.post('/planning/lists/$listId/items', data: item);
      return resolveListAfterMutation(listId, response.data);
    } on DioException catch (e) {
      throw Exception(_message(e, 'Error al agregar producto'));
    }
  }

  Future<Map<String, dynamic>> removeItem(int listId, int itemId) async {
    try {
      final response = await _client.dio.delete('/planning/lists/$listId/items/$itemId');
      return resolveListAfterMutation(listId, response.data);
    } on DioException catch (e) {
      throw Exception(_message(e, 'Error al quitar producto'));
    }
  }

  Future<Map<String, dynamic>> applyFamilyBasket(int buyerId, int listId) async {
    try {
      final response = await _client.dio.post('/planning/buyers/$buyerId/lists/$listId/apply-family-basket');
      return resolveListAfterMutation(listId, response.data);
    } on DioException catch (e) {
      throw Exception(_message(e, 'Error al aplicar canasta familiar'));
    }
  }

  List<Map<String, dynamic>> _asListOfMaps(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (data is Map) {
      if (data.containsKey('id') || data.containsKey('listId')) {
        return [Map<String, dynamic>.from(data)];
      }
      final nested = data['content'] ?? data['items'] ?? data['lists'];
      if (nested is List) {
        return nested.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    return [];
  }

  String _message(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    return fallback;
  }
}
