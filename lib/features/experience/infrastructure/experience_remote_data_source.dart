import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class ExperienceRemoteDataSource {
  final DioClient _client;

  ExperienceRemoteDataSource(this._client);

  Future<Map<String, dynamic>> rateStore({
    required String storeId,
    required String buyerId,
    required String recorridoId,
    required int puntuacion,
  }) async {
    try {
      final response = await _client.dio.post('/experience/stores/$storeId/ratings', data: {
        'buyerId': buyerId,
        'recorridoId': recorridoId,
        'puntuacion': puntuacion,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al calificar tienda'));
    }
  }

  Future<Map<String, dynamic>> postReview({
    required String storeId,
    required String buyerId,
    required String recorridoId,
    required String comentario,
  }) async {
    try {
      final response = await _client.dio.post('/experience/stores/$storeId/reviews', data: {
        'buyerId': buyerId,
        'recorridoId': recorridoId,
        'comentario': comentario,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al publicar reseña'));
    }
  }

  Future<List<Map<String, dynamic>>> getPublishedReviews(String storeId, {int page = 0, int size = 10}) async {
    try {
      final response = await _client.dio.get(
        '/experience/stores/$storeId/reviews',
        queryParameters: {'page': page, 'size': size},
      );
      return _asMapList(response.data);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al obtener reseñas'));
    }
  }

  Future<Map<String, dynamic>> reportPriceError({
    required String storeId,
    required String buyerId,
    required String recorridoId,
    required String productoId,
    required double precioDigital,
    required double precioFisico,
    required String moneda,
  }) async {
    try {
      final response = await _client.dio.post('/experience/stores/$storeId/price-errors', data: {
        'buyerId': buyerId,
        'recorridoId': recorridoId,
        'productoId': productoId,
        'precioDigital': precioDigital,
        'precioFisico': precioFisico,
        'moneda': moneda,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al reportar precio'));
    }
  }

  Future<Map<String, dynamic>> calculateSavings({
    required String recorridoId,
    required String buyerId,
    required double precioReferencia,
    required double precioPagado,
    required String moneda,
  }) async {
    try {
      final response = await _client.dio.post('/experience/journeys/$recorridoId/savings', data: {
        'buyerId': buyerId,
        'precioReferencia': precioReferencia,
        'precioPagado': precioPagado,
        'moneda': moneda,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al calcular ahorro'));
    }
  }

  Future<Map<String, dynamic>> getSavings(String recorridoId) async {
    try {
      final response = await _client.dio.get('/experience/journeys/$recorridoId/savings');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al obtener ahorro'));
    }
  }

  Future<Map<String, dynamic>> getTrustProfile(String storeId) async {
    try {
      final response = await _client.dio.get('/experience/stores/$storeId/trust-profile');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al obtener perfil de confianza'));
    }
  }

  Future<Map<String, dynamic>> getStoreRatings(String storeId) async {
    try {
      final response = await _client.dio.get('/experience/stores/$storeId/ratings');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, 'Error al obtener calificaciones'));
    }
  }

  String _extractMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return fallback;
  }

  List<Map<String, dynamic>> _asMapList(dynamic data) {
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map) {
      final content = data['content'] as List<dynamic>? ?? data['items'] as List<dynamic>?;
      if (content != null) return content.cast<Map<String, dynamic>>();
    }
    return [];
  }
}
