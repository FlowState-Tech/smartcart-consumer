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
      } else {
        throw Exception('Failed to compare prices');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Network error during comparison');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
