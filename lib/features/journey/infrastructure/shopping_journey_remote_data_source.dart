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
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al crear la ruta'));
    }
  }

  Future<List<Map<String, dynamic>>> findRoutes(int buyerId, {int? listId}) async {
    try {
      final response = await _client.dio.get('/journey/routes', queryParameters: {
        'buyerId': buyerId,
        if (listId != null) 'listId': listId,
      });
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al buscar rutas'));
    }
  }

  Future<Map<String, dynamic>> getRoute(String routeId) async {
    try {
      final response = await _client.dio.get('/journey/routes/$routeId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al obtener la ruta'));
    }
  }

  Future<Map<String, dynamic>> defineResidence(
    String routeId,
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _client.dio.post('/journey/routes/$routeId/residence', data: {
        'latitude': latitude,
        'longitude': longitude,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al definir residencia'));
    }
  }

  Future<Map<String, dynamic>> selectDestination(String routeId, int storeId) async {
    try {
      final response = await _client.dio.post('/journey/routes/$routeId/destination', data: {
        'storeId': storeId,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al seleccionar tienda'));
    }
  }

  Future<Map<String, dynamic>> requestPath(String routeId) async {
    try {
      final response = await _client.dio.post('/journey/routes/$routeId/request-path');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al solicitar trayecto'));
    }
  }

  Future<Map<String, dynamic>> getOptimalView(String routeId) async {
    try {
      final response = await _client.dio.get('/journey/routes/$routeId/optimal-view');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al obtener vista óptima'));
    }
  }

  Future<Map<String, dynamic>> optimizeRoute(String routeId, List<int> storeIds) async {
    try {
      final response = await _client.dio.post('/journey/routes/$routeId/optimize', data: {
        'storeIds': storeIds,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al optimizar ruta'));
    }
  }

  Future<Map<String, dynamic>> startNavigation(String routeId) async {
    try {
      final response = await _client.dio.post('/journey/routes/$routeId/start-navigation');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al iniciar navegación'));
    }
  }

  Future<Map<String, dynamic>> registerArrival(
    String routeId,
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await _client.dio.post('/journey/routes/$routeId/register-arrival', data: {
        'latitude': latitude,
        'longitude': longitude,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al registrar llegada'));
    }
  }

  Future<Map<String, dynamic>> finishJourney(String routeId) async {
    try {
      final response = await _client.dio.post('/journey/routes/$routeId/finish');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al finalizar recorrido'));
    }
  }

  String _extractMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return fallback;
  }
}
