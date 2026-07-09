import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class ShoppingJourneyRemoteDataSource {
  final DioClient _client;

  ShoppingJourneyRemoteDataSource(this._client);

  Future<Map<String, dynamic>> createRoute(int buyerId, int listId) async {
    try {
      final response = await _client.dio.post('/journey/routes', data: {
        'buyerId': buyerId,
        'listId': listId,
      });
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error creating route');
    }
  }

  Future<Map<String, dynamic>> optimizeRoute(String routeId, List<String> storeIds) async {
    try {
      final response = await _client.dio.post('/journey/routes/$routeId/optimize', data: {
        'storeIds': storeIds,
      });
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error optimizing route');
    }
  }

  Future<Map<String, dynamic>> startNavigation(String routeId) async {
    try {
      final response = await _client.dio.post('/journey/routes/$routeId/start-navigation');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error starting navigation');
    }
  }

  Future<Map<String, dynamic>> finishJourney(String routeId) async {
    try {
      final response = await _client.dio.post('/journey/routes/$routeId/finish');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error finishing journey');
    }
  }
}
