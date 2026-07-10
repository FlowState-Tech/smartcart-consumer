import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/basket_pdf_exporter.dart';
import '../../../core/services/favorites_storage.dart';
import '../domain/shopping_list.dart';
import '../domain/value_objects.dart';
import '../domain/entities.dart';
import '../domain/domain_services.dart';
import 'basket_state.dart';
import '../../../core/di/injection_container.dart';
import '../infrastructure/shopping_list_remote_data_source.dart';
import '../infrastructure/preferences_remote_data_source.dart';
import '../infrastructure/comparison_remote_data_source.dart';
import '../infrastructure/product_catalog_service.dart';
import '../infrastructure/store_remote_data_source.dart';
import '../../../core/providers/session_providers.dart';

typedef BuyerIdResolver = int Function();

class BasketNotifier extends StateNotifier<BasketState> {
  final ShoppingListRemoteDataSource _dataSource;
  final PreferencesRemoteDataSource _preferencesDataSource;
  final ComparisonRemoteDataSource _comparisonDataSource;
  final ProductCatalogService _catalogService;
  final StoreRemoteDataSource _storeDataSource;
  final FavoritesStorage _favoritesStorage;
  final BuyerIdResolver _getBuyerId;

  BasketNotifier(
    this._dataSource,
    this._preferencesDataSource,
    this._comparisonDataSource,
    this._catalogService,
    this._storeDataSource,
    this._favoritesStorage, {
    BuyerIdResolver? getBuyerId,
  })  : _getBuyerId = getBuyerId ?? (() => 1),
        super(const BasketState(shoppingList: ShoppingList(id: 'default', items: []))) {
    Future.microtask(() async {
      await _loadFavorites();
      await _loadPreferencesBudget();
      await _loadPreferredStoresFromBackend();
      await _restoreLastListIfEmpty();
    });
  }

  Future<void> restoreSessionIfNeeded() => _restoreLastListIfEmpty();

  Future<void> _restoreLastListIfEmpty() async {
    if (state.shoppingList.items.isNotEmpty || state.remoteListId != null) return;
    try {
      final lists = await _dataSource.getListsByBuyer(_getBuyerId());
      if (lists.isEmpty) return;
      final last = lists.last as Map<String, dynamic>;
      final listId = (last['id'] as num?)?.toInt();
      if (listId != null) await switchToList(listId);
    } catch (_) {}
  }

  Future<void> _loadPreferredStoresFromBackend() async {
    try {
      final prefs = await _preferencesDataSource.getPreferences(_getBuyerId());
      final storeIds = (prefs['preferredStoreIds'] as List<dynamic>?) ?? [];
      if (storeIds.isEmpty) return;

      final merged = <int, Map<String, dynamic>>{
        for (final s in state.favoriteStores) (s['storeId'] as num).toInt(): s,
      };

      for (final rawId in storeIds) {
        final id = (rawId as num).toInt();
        if (merged.containsKey(id)) continue;
        try {
          final profile = await _storeDataSource.getStoreProfile(id);
          merged[id] = {
            'storeId': id,
            'storeName': profile['name'] ?? profile['storeName'] ?? 'Tienda $id',
          };
        } catch (_) {
          merged[id] = {'storeId': id, 'storeName': 'Tienda $id'};
        }
      }
      state = state.copyWith(favoriteStores: merged.values.toList());
    } catch (_) {}
  }

  void setApiTotalCost(double? total) {
    state = state.copyWith(apiTotalCost: total, clearApiTotal: total == null);
  }

  void setSelectedStoreId(int? storeId) {
    state = state.copyWith(selectedStoreId: storeId, clearSelectedStore: storeId == null);
  }

  Future<List<Map<String, dynamic>>> fetchBuyerLists() async {
    try {
      final lists = await _dataSource.getListsByBuyer(_getBuyerId());
      final typed = lists.cast<Map<String, dynamic>>();
      state = state.copyWith(buyerLists: typed);
      return typed;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return [];
    }
  }

  Future<void> switchToList(int listId) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final listData = await _dataSource.getList(listId);
      state = state.copyWith(remoteListId: listId, clearApiTotal: true);
      await _applyRemoteList(listData, successMessage: 'Canasta cargada');
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> _loadFavorites() async {
    final products = await _favoritesStorage.loadProducts();
    final stores = await _favoritesStorage.loadStores();
    state = state.copyWith(favoriteProducts: products, favoriteStores: stores);
  }

  Future<void> _loadPreferencesBudget() async {
    try {
      final prefs = await _preferencesDataSource.getPreferences(_getBuyerId());
      final amount = (prefs['budgetAmount'] as num?)?.toDouble();
      if (amount != null && amount > 0) {
        state = state.copyWith(budget: Budget(amount));
      }
    } catch (_) {}
  }

  ShoppingList _mergeRemoteList(Map<String, dynamic> data) {
    final itemsRaw = data['items'] as List<dynamic>? ?? [];
    final previousBySku = {for (final i in state.shoppingList.items) i.id: i};

    final items = itemsRaw.map((raw) {
      final item = raw as Map<String, dynamic>;
      final sku = item['sku'] as String? ?? item['id'].toString();
      final previous = previousBySku[sku];
      return ProductItem(
        id: sku,
        remoteItemId: (item['id'] as num?)?.toInt(),
        name: item['productName'] as String? ?? previous?.name ?? 'Producto',
        brand: previous?.brand ?? '',
        price: previous?.price ?? 0,
        quantity: Quantity((item['quantity'] as num?)?.toDouble() ?? 1, item['unit'] as String? ?? 'unit'),
        storeType: previous?.storeType ?? 'supermarket',
        normalizedUnitPrice: previous?.normalizedUnitPrice,
      );
    }).toList();

    return ShoppingList(
      id: (data['id'] ?? data['listId'] ?? 'default').toString(),
      items: items,
    );
  }

  Future<ShoppingList> _enrichPrices(ShoppingList list) async {
    final enriched = <ProductItem>[];
    for (final item in list.items) {
      if (item.price > 0) {
        enriched.add(item);
        continue;
      }
      final price = await _catalogService.lookupPrice(item.id, buyerId: _getBuyerId());
      enriched.add(item.copyWith(price: price ?? item.price));
    }
    return ShoppingList(id: list.id, items: enriched);
  }

  Future<void> _applyRemoteList(Map<String, dynamic> data, {String? successMessage}) async {
    var list = _mergeRemoteList(data);
    list = await _enrichPrices(list);
    state = state.copyWith(shoppingList: list, successMessage: successMessage, isLoading: false);
  }

  Future<void> setBudget(double amount) async {
    try {
      final budget = Budget(amount);
      state = state.copyWith(budget: budget, clearMessages: true);
      await _preferencesDataSource.updatePreferences(_getBuyerId(), {
        'budgetAmount': amount,
        'budgetCurrency': 'PEN',
      });
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> addProduct(ProductItem rawItem) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    var normalizedItem = UnitMeasureComparisonService.normalizePrice(rawItem);
    if (normalizedItem.price <= 0) {
      final price = await _catalogService.lookupPrice(normalizedItem.id, buyerId: _getBuyerId());
      if (price != null) normalizedItem = normalizedItem.copyWith(price: price);
    }

    try {
      final buyerId = _getBuyerId();
      int listId;

      if (state.remoteListId != null) {
        listId = state.remoteListId!;
      } else {
        final createRes = await _dataSource.createList(
          buyerId,
          'Mi Canasta ${DateTime.now().millisecondsSinceEpoch % 10000}',
        );
        listId = (createRes['id'] as num?)?.toInt() ?? 1;
        state = state.copyWith(remoteListId: listId);
      }

      final listResponse = await _dataSource.addItem(listId, {
        'sku': normalizedItem.id,
        'productName': normalizedItem.name,
        'quantity': normalizedItem.quantity.value,
        'unit': normalizedItem.quantity.unit,
      });

      await _applyRemoteList(listResponse, successMessage: '${normalizedItem.name} añadido');

      await _suggestSubstituteFromApi(normalizedItem);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> removeProduct(String productId) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final item = state.shoppingList.items.firstWhere((i) => i.id == productId);
      if (state.remoteListId != null && item.remoteItemId != null) {
        final listResponse = await _dataSource.removeItem(state.remoteListId!, item.remoteItemId!);
        await _applyRemoteList(listResponse);
      } else {
        state = state.copyWith(
          isLoading: false,
          shoppingList: state.shoppingList.removeItem(productId),
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> updateProductQuantity(String productId, int newQuantity) async {
    if (newQuantity < 1) {
      await removeProduct(productId);
      return;
    }

    final item = state.shoppingList.items.where((i) => i.id == productId).firstOrNull;
    if (item == null) return;
    if (item.quantity.value.toInt() == newQuantity) return;

    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      if (state.remoteListId != null && item.remoteItemId != null) {
        var listResponse = await _dataSource.removeItem(state.remoteListId!, item.remoteItemId!);
        listResponse = await _dataSource.addItem(state.remoteListId!, {
          'sku': item.id,
          'productName': item.name,
          'quantity': newQuantity.toDouble(),
          'unit': item.quantity.unit,
        });
        await _applyRemoteList(listResponse);
      } else {
        state = state.copyWith(
          isLoading: false,
          shoppingList: state.shoppingList.updateItemQuantity(productId, newQuantity),
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> repeatLastBasket() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final buyerId = _getBuyerId();
      final lists = await _dataSource.getListsByBuyer(buyerId);
      if (lists.isEmpty) {
        state = state.copyWith(isLoading: false, errorMessage: 'No hay canastas anteriores');
        return;
      }

      final last = lists.last as Map<String, dynamic>;
      final listId = (last['id'] as num?)?.toInt();
      if (listId == null) throw Exception('Lista inválida');

      final listData = await _dataSource.getList(listId);
      state = state.copyWith(remoteListId: listId);
      await _applyRemoteList(listData, successMessage: 'Canasta "${last['name'] ?? 'anterior'}" cargada');
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<Uint8List?> exportPdf() async {
    if (state.shoppingList.items.isEmpty) {
      state = state.copyWith(errorMessage: 'La canasta está vacía');
      return null;
    }
    return BasketPdfExporter.export(
      listName: 'Mi Canasta',
      items: state.shoppingList.items,
      total: state.shoppingList.getTotalCost(),
    );
  }

  Future<void> applyFamilyBasket() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final buyerId = _getBuyerId();
      int listId = state.remoteListId ?? 0;
      if (listId == 0) {
        final createRes = await _dataSource.createList(buyerId, 'Canasta familiar');
        listId = (createRes['id'] as num?)?.toInt() ?? 1;
        state = state.copyWith(remoteListId: listId);
      }
      final listResponse = await _dataSource.applyFamilyBasket(buyerId, listId);
      await _applyRemoteList(listResponse, successMessage: 'Canasta básica familiar aplicada');
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> toggleFavoriteProduct(Map<String, dynamic> product) async {
    final updated = await _favoritesStorage.toggleProduct(product);
    state = state.copyWith(favoriteProducts: updated);
  }

  Future<void> _suggestSubstituteFromApi(ProductItem item) async {
    final storeId = state.selectedStoreId;
    final listId = state.remoteListId;
    if (storeId == null || listId == null) {
      final fallback = SubstituteProductPolicyService.suggestSubstitute(item);
      if (fallback != null) state = state.copyWith(suggestedSubstitute: fallback);
      return;
    }
    try {
      final sub = await _comparisonDataSource.getSubstitute(listId, storeId, item.id);
      final substituteItem = ProductItem(
        id: sub['substituteSku'] as String? ?? sub['sku'] as String? ?? 'sub',
        name: sub['substituteName'] as String? ?? sub['productName'] as String? ?? 'Sustituto',
        brand: sub['brand'] as String? ?? '',
        price: (sub['price'] as num?)?.toDouble() ?? 0,
        quantity: Quantity(1, 'unit'),
        storeType: item.storeType,
      );
      state = state.copyWith(suggestedSubstitute: substituteItem);
    } catch (_) {
      final fallback = SubstituteProductPolicyService.suggestSubstitute(item);
      if (fallback != null) state = state.copyWith(suggestedSubstitute: fallback);
    }
  }

  Future<void> toggleFavoriteStore(Map<String, dynamic> store) async {
    final updated = await _favoritesStorage.toggleStore(store);
    state = state.copyWith(favoriteStores: updated);
    try {
      final storeIds = updated.map((s) => (s['storeId'] as num).toInt()).toList();
      await _preferencesDataSource.updatePreferredStores(_getBuyerId(), storeIds);
    } catch (_) {}
  }

  bool isFavoriteProduct(String sku) {
    return state.favoriteProducts.any((p) => (p['sku'] ?? p['id']).toString() == sku);
  }

  bool isFavoriteStore(int storeId) {
    return state.favoriteStores.any((s) => (s['storeId'] as num?)?.toInt() == storeId);
  }

  Future<void> addFavoriteToBasket(Map<String, dynamic> product) async {
    await addProduct(
      ProductItem(
        id: product['sku']?.toString() ?? product['id']?.toString() ?? '',
        name: product['name']?.toString() ?? product['productName']?.toString() ?? 'Producto',
        brand: product['brand']?.toString() ?? '',
        price: (product['price'] as num?)?.toDouble() ?? 0,
        quantity: Quantity(1, 'unit'),
        storeType: 'supermarket',
      ),
    );
  }

  Future<void> acceptSubstitute(ProductItem originalItem, ProductItem substituteItem) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      if (state.remoteListId != null && originalItem.remoteItemId != null) {
        await _dataSource.removeItem(state.remoteListId!, originalItem.remoteItemId!);
        final listResponse = await _dataSource.addItem(state.remoteListId!, {
          'sku': substituteItem.id,
          'productName': substituteItem.name,
          'quantity': substituteItem.quantity.value,
          'unit': substituteItem.quantity.unit,
        });
        await _applyRemoteList(listResponse, successMessage: 'Sustituto aplicado');
      } else {
        final listWithoutOriginal = state.shoppingList.removeItem(originalItem.id);
        state = state.copyWith(
          isLoading: false,
          shoppingList: listWithoutOriginal.addItem(substituteItem),
        );
      }
      state = state.copyWith(clearSubstitute: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> checkSubstitutesForStore(int storeId) async {
    if (state.remoteListId == null) return;
    try {
      final substitutes = await _comparisonDataSource.getAllSubstitutes(state.remoteListId!, storeId);
      if (substitutes.isEmpty) return;
      final first = substitutes.first;
      final substituteItem = ProductItem(
        id: first['substituteSku'] as String? ?? 'sub',
        name: first['substituteName'] as String? ?? 'Sustituto',
        brand: '',
        price: 0,
        quantity: Quantity(1, 'unit'),
        storeType: 'supermarket',
      );
      final originalSku = first['originalSku'] as String?;
      final original = state.shoppingList.items.where((i) => i.id == originalSku).firstOrNull;
      if (original != null) {
        state = state.copyWith(suggestedSubstitute: substituteItem);
      }
    } catch (_) {}
  }

  void dismissSubstitute() {
    state = state.copyWith(clearSubstitute: true);
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }

  Future<void> clearAllLocalData() async {
    await _favoritesStorage.clearAll();
    state = const BasketState(shoppingList: ShoppingList(id: 'default', items: []));
  }
}

final basketProvider = StateNotifierProvider<BasketNotifier, BasketState>((ref) {
  return BasketNotifier(
    sl<ShoppingListRemoteDataSource>(),
    sl<PreferencesRemoteDataSource>(),
    sl<ComparisonRemoteDataSource>(),
    sl<ProductCatalogService>(),
    sl<StoreRemoteDataSource>(),
    sl<FavoritesStorage>(),
    getBuyerId: () => ref.read(currentBuyerIdProvider),
  );
});
