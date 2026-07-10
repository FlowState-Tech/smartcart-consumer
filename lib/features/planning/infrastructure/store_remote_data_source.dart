import 'package:dio/dio.dart';
import '../../../core/network/api_response_utils.dart';
import '../../../core/network/dio_client.dart';

class StoreRemoteDataSource {
  final DioClient _client;

  StoreRemoteDataSource(this._client);

  Future<Map<String, dynamic>> getStoreProfile(int storeId) async {
    try {
      final response = await _client.dio.get('/store-management/stores/$storeId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al obtener tienda');
    }
  }

  Future<List<Map<String, dynamic>>> searchInventory(
    int storeId, {
    String? sku,
    String? category,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final response = await _client.dio.get(
        '/store-management/stores/$storeId/inventory',
        queryParameters: {
          if (sku != null && sku.isNotEmpty) 'sku': sku,
          if (category != null && category.isNotEmpty) 'category': category,
          'page': page,
          'size': size,
        },
      );
      final data = response.data;
      return ApiResponseUtils.asListOfMaps(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error al buscar inventario');
    }
  }
}
