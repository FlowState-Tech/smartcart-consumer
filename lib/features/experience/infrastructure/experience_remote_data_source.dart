import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class ExperienceRemoteDataSource {
  final DioClient _client;

  ExperienceRemoteDataSource(this._client);

  Future<Map<String, dynamic>> rateStore(String storeId, int score, String comment) async {
    try {
      final response = await _client.dio.post('/experience/stores/$storeId/ratings', data: {
        'score': score,
        'comment': comment,
      });
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error rating store');
    }
  }

  Future<Map<String, dynamic>> reportPriceError(String storeId, String sku, double reportedPrice, String evidenceUrl) async {
    try {
      final response = await _client.dio.post('/experience/stores/$storeId/price-errors', data: {
        'sku': sku,
        'reportedPrice': reportedPrice,
        'evidenceUrl': evidenceUrl,
      });
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error reporting price error');
    }
  }

  Future<Map<String, dynamic>> calculateSavings(String routeId, List<String> scannedSkus) async {
    try {
      final response = await _client.dio.post('/experience/journeys/$routeId/savings', data: {
        'scannedSkus': scannedSkus,
      });
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error calculating savings');
    }
  }
}
