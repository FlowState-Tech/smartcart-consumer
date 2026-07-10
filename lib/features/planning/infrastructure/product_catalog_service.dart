import 'comparison_remote_data_source.dart';
import 'store_remote_data_source.dart';
import 'preferences_remote_data_source.dart';

/// Resolves product metadata using barcode API and store inventory.
class ProductCatalogService {
  final ComparisonRemoteDataSource _comparisonDataSource;
  final StoreRemoteDataSource _storeDataSource;
  final PreferencesRemoteDataSource _preferencesDataSource;

  ProductCatalogService(
    this._comparisonDataSource,
    this._storeDataSource,
    this._preferencesDataSource,
  );

  static const _defaultStoreIds = [1, 2, 3, 101, 102];

  static const seedCatalog = [
    {'sku': '7751234567890', 'name': 'Leche Gloria', 'brand': 'Gloria', 'barcode': '7751234567890'},
    {'sku': '7759876543210', 'name': 'Pan Bimbo', 'brand': 'Bimbo', 'barcode': '7759876543210'},
    {'sku': '7751112223334', 'name': 'Arroz Costeño', 'brand': 'Costeño', 'barcode': '7751112223334'},
    {'sku': '7754445556667', 'name': 'Huevos La Calera', 'brand': 'La Calera', 'barcode': '7754445556667'},
    {'sku': '7757778889990', 'name': 'Aceite Primor', 'brand': 'Primor', 'barcode': '7757778889990'},
  ];

  Future<List<int>> _resolveStoreIds(int? buyerId) async {
    if (buyerId != null) {
      try {
        final prefs = await _preferencesDataSource.getPreferences(buyerId);
        final ids = (prefs['preferredStoreIds'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList();
        if (ids != null && ids.isNotEmpty) return ids;
      } catch (_) {}
    }
    return _defaultStoreIds;
  }

  Future<List<Map<String, dynamic>>> search(String query, {int? buyerId}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    if (RegExp(r'^\d{8,}$').hasMatch(q)) {
      return _lookupBarcode(q);
    }

    final storeIds = await _resolveStoreIds(buyerId);
    final inventoryResults = await _searchInventoryByName(q, storeIds);
    if (inventoryResults.isNotEmpty) return inventoryResults;

    final localMatches = seedCatalog.where((item) {
      return item['name'].toString().toLowerCase().contains(q) ||
          item['brand'].toString().toLowerCase().contains(q);
    });

    final results = <Map<String, dynamic>>[];
    for (final item in localMatches) {
      final enriched = await _lookupBarcode(item['barcode'] as String);
      if (enriched.isNotEmpty) {
        results.add(enriched.first);
      } else {
        results.add({...item, 'price': 0.0});
      }
    }
    return results;
  }

  Future<List<Map<String, dynamic>>> _searchInventoryByName(String query, List<int> storeIds) async {
    final aggregated = <Map<String, dynamic>>[];
    for (final storeId in storeIds) {
      try {
        final items = await _storeDataSource.searchInventory(storeId, size: 100);
        for (final item in items) {
          final name = (item['name'] ?? item['productName'] ?? '').toString().toLowerCase();
          final sku = (item['sku'] ?? '').toString().toLowerCase();
          if (name.contains(query) || sku.contains(query)) {
            aggregated.add(_mapInventoryItem(item, storeId));
          }
        }
        if (aggregated.length >= 20) break;
      } catch (_) {}
    }
    return aggregated;
  }

  Map<String, dynamic> _mapInventoryItem(Map<String, dynamic> item, int storeId) {
    return {
      'sku': item['sku'],
      'name': item['name'] ?? item['productName'],
      'brand': item['brand'] ?? item['category'] ?? '',
      'price': (item['price'] as num?)?.toDouble() ?? 0,
      'storeId': storeId,
      'stock': item['stock'],
    };
  }

  Future<double?> lookupPrice(String skuOrBarcode, {int? buyerId}) async {
    final results = await _lookupBarcode(skuOrBarcode);
    if (results.isNotEmpty) {
      return (results.first['price'] as num?)?.toDouble();
    }
    final storeIds = await _resolveStoreIds(buyerId);
    for (final storeId in storeIds) {
      try {
        final items = await _storeDataSource.searchInventory(storeId, sku: skuOrBarcode);
        if (items.isNotEmpty) {
          return (items.first['price'] as num?)?.toDouble();
        }
      } catch (_) {}
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _lookupBarcode(String barcode) async {
    try {
      final apiResults = await _comparisonDataSource.lookupBarcode(barcode);
      return apiResults
          .map((r) => {
                'sku': r['sku'],
                'name': r['productName'],
                'brand': r['storeName'] ?? '',
                'price': (r['price'] as num?)?.toDouble() ?? 0,
                'storeId': r['storeId'],
                'storeName': r['storeName'],
              })
          .toList();
    } catch (_) {
      return [];
    }
  }
}
