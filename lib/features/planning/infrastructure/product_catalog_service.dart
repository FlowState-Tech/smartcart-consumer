import '../../../core/network/api_response_utils.dart';
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

  static const _defaultStoreIds = [1, 2, 3];

  static const seedCatalog = [
    {'sku': 'GL-123', 'name': 'Leche Gloria', 'brand': 'Gloria'},
    {'sku': 'BI-456', 'name': 'Pan Bimbo', 'brand': 'Bimbo'},
    {'sku': 'AR-789', 'name': 'Arroz Costeño', 'brand': 'Costeño'},
    {'sku': 'HU-012', 'name': 'Huevos La Calera', 'brand': 'La Calera'},
    {'sku': 'AC-345', 'name': 'Aceite Primor', 'brand': 'Primor'},
  ];

  Future<List<int>> _resolveStoreIds(int? buyerId) async {
    if (buyerId != null) {
      try {
        final prefs = await _preferencesDataSource.getPreferences(buyerId);
        final ids = (prefs['preferredStoreIds'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .where((id) => id > 0)
            .toList();
        if (ids != null && ids.isNotEmpty) return ids;
      } catch (_) {}
    }
    return _defaultStoreIds;
  }

  Future<List<Map<String, dynamic>>> getPopularProducts({int? buyerId}) async {
    final fromSeed = await _loadSeedCatalogFromApi();
    if (fromSeed.isNotEmpty) return fromSeed;

    final storeIds = await _resolveStoreIds(buyerId);
    for (final storeId in storeIds) {
      try {
        final items = await _storeDataSource.searchInventory(storeId, size: 25);
        if (items.isNotEmpty) {
          return items.map((item) => _mapInventoryItem(item, storeId)).toList();
        }
      } catch (_) {}
    }

    return _seedFallbackWithoutPrices();
  }

  Future<List<Map<String, dynamic>>> search(String query, {int? buyerId}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getPopularProducts(buyerId: buyerId);

    if (RegExp(r'^[A-Za-z0-9-]{3,}$').hasMatch(q)) {
      final barcodeResults = await _lookupBarcode(q.toUpperCase());
      if (barcodeResults.isNotEmpty) return barcodeResults;
    }

    final storeIds = await _resolveStoreIds(buyerId);
    final inventoryResults = await _searchInventoryByName(q, storeIds);
    if (inventoryResults.isNotEmpty) return inventoryResults;

    final localMatches = seedCatalog.where((item) {
      return item['name'].toString().toLowerCase().contains(q) ||
          item['brand'].toString().toLowerCase().contains(q) ||
          item['sku'].toString().toLowerCase().contains(q);
    });

    final results = <Map<String, dynamic>>[];
    for (final item in localMatches) {
      final sku = item['sku'] as String;
      final enriched = await _lookupBarcode(sku);
      if (enriched.isNotEmpty) {
        results.add(enriched.first);
      } else {
        results.add({...item, 'price': 0.0});
      }
    }
    return results;
  }

  Future<List<Map<String, dynamic>>> _loadSeedCatalogFromApi() async {
    final results = <Map<String, dynamic>>[];
    final seen = <String>{};

    await Future.wait(seedCatalog.map((item) async {
      final sku = item['sku'] as String;
      final api = await _lookupBarcode(sku);
      if (api.isNotEmpty) {
        final mapped = api.first;
        if (seen.add(mapped['sku'].toString())) results.add(mapped);
      }
    }));

    if (results.isNotEmpty) return results;
    return [];
  }

  List<Map<String, dynamic>> _seedFallbackWithoutPrices() {
    return seedCatalog
        .map((item) => {
              'sku': item['sku'],
              'name': item['name'],
              'brand': item['brand'],
              'price': 0.0,
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> _searchInventoryByName(String query, List<int> storeIds) async {
    final aggregated = <Map<String, dynamic>>[];
    final seen = <String>{};
    for (final storeId in storeIds) {
      try {
        final items = await _storeDataSource.searchInventory(storeId, size: 100);
        for (final item in items) {
          final name = (item['name'] ?? item['productName'] ?? '').toString().toLowerCase();
          final sku = (item['sku'] ?? '').toString();
          if (name.contains(query) || sku.toLowerCase().contains(query)) {
            if (seen.add(sku)) {
              aggregated.add(_mapInventoryItem(item, storeId));
            }
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
      'price': ApiResponseUtils.readPrice(item) ?? 0,
      'storeId': storeId,
      'stock': item['quantity'] ?? item['stock'],
    };
  }

  Map<String, dynamic> _mapBarcodeItem(Map<String, dynamic> r) {
    return {
      'sku': r['sku'],
      'name': r['productName'] ?? r['name'],
      'brand': r['brand'] ?? r['storeName'] ?? '',
      'price': ApiResponseUtils.readPrice(r) ?? 0,
      'storeId': r['storeId'],
      'storeName': r['storeName'],
    };
  }

  Future<double?> lookupPrice(String skuOrBarcode, {int? buyerId}) async {
    final normalized = skuOrBarcode.trim().toUpperCase();
    final results = await _lookupBarcode(normalized);
    if (results.isNotEmpty) {
      return (results.first['price'] as num?)?.toDouble();
    }
    final storeIds = await _resolveStoreIds(buyerId);
    for (final storeId in storeIds) {
      try {
        final items = await _storeDataSource.searchInventory(storeId, sku: normalized);
        if (items.isNotEmpty) {
          return _mapInventoryItem(items.first, storeId)['price'] as double?;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _lookupBarcode(String barcode) async {
    try {
      final apiResults = await _comparisonDataSource.lookupBarcode(barcode);
      return apiResults.map(_mapBarcodeItem).toList();
    } catch (_) {
      return [];
    }
  }
}
