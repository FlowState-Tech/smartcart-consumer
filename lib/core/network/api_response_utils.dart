/// Normalizes backend payloads that may be a raw list, a single object, or wrapped.
class ApiResponseUtils {
  static List<Map<String, dynamic>> asListOfMaps(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (_looksLikeRecord(map)) return [map];
      for (final key in const ['content', 'items', 'results', 'data', 'lists']) {
        final nested = map[key];
        if (nested is List) return asListOfMaps(nested);
      }
    }
    return [];
  }

  static bool _looksLikeRecord(Map<String, dynamic> map) {
    return map.containsKey('sku') ||
        map.containsKey('id') ||
        map.containsKey('listId') ||
        map.containsKey('productName') ||
        map.containsKey('storeId');
  }

  static double? readPrice(Map<String, dynamic> map) {
    for (final key in const ['priceAmount', 'price', 'unitPrice', 'totalPrice']) {
      final value = map[key];
      if (value is num) return value.toDouble();
    }
    return null;
  }
}
