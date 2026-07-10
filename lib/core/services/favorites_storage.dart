import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FavoritesStorage {
  final FlutterSecureStorage _storage;
  static const _productsKey = 'favorite_products_json';
  static const _storesKey = 'favorite_stores_json';

  FavoritesStorage(this._storage);

  Future<List<Map<String, dynamic>>> loadProducts() async {
    return _loadList(_productsKey);
  }

  Future<List<Map<String, dynamic>>> loadStores() async {
    return _loadList(_storesKey);
  }

  Future<List<Map<String, dynamic>>> toggleProduct(Map<String, dynamic> product) async {
    return _toggle(_productsKey, product, 'sku', 'id');
  }

  Future<List<Map<String, dynamic>>> toggleStore(Map<String, dynamic> store) async {
    return _toggle(_storesKey, store, 'storeId', 'storeId');
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _productsKey);
    await _storage.delete(key: _storesKey);
  }

  Future<List<Map<String, dynamic>>> _loadList(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded.cast<Map<String, dynamic>>();
    return [];
  }

  Future<List<Map<String, dynamic>>> _toggle(
    String key,
    Map<String, dynamic> item,
    String primaryField,
    String fallbackField,
  ) async {
    final items = await _loadList(key);
    final id = item[primaryField]?.toString() ?? item[fallbackField]?.toString();
    final index = items.indexWhere((i) => (i[primaryField] ?? i[fallbackField]).toString() == id);
    if (index >= 0) {
      items.removeAt(index);
    } else {
      items.add(item);
    }
    await _storage.write(key: key, value: jsonEncode(items));
    return items;
  }

  @Deprecated('Use loadProducts')
  Future<List<Map<String, dynamic>>> load() => loadProducts();

  @Deprecated('Use toggleProduct')
  Future<List<Map<String, dynamic>>> toggle(Map<String, dynamic> product) => toggleProduct(product);
}
