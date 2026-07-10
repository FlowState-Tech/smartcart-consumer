import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../infrastructure/comparison_remote_data_source.dart';
import '../infrastructure/store_remote_data_source.dart';
import '../../experience/infrastructure/experience_remote_data_source.dart';
import '../../../core/di/injection_container.dart';

class ComparisonState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> results;
  final Map<String, dynamic>? selectedStore;
  final Set<int> selectedStoreIds;
  final Map<int, Map<String, double>> storeCoordinates;
  final Map<String, dynamic>? apiTotalCost;
  final List<String> stockIssues;
  final Map<String, dynamic>? trustProfile;
  final Map<int, Map<String, dynamic>> storeRatings;

  const ComparisonState({
    this.isLoading = false,
    this.error,
    this.results = const [],
    this.selectedStore,
    this.selectedStoreIds = const {},
    this.storeCoordinates = const {},
    this.apiTotalCost,
    this.stockIssues = const [],
    this.trustProfile,
    this.storeRatings = const {},
  });

  ComparisonState copyWith({
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? results,
    Map<String, dynamic>? selectedStore,
    Set<int>? selectedStoreIds,
    Map<int, Map<String, double>>? storeCoordinates,
    Map<String, dynamic>? apiTotalCost,
    List<String>? stockIssues,
    Map<String, dynamic>? trustProfile,
    Map<int, Map<String, dynamic>>? storeRatings,
    bool clearSelected = false,
    bool clearTrust = false,
  }) {
    return ComparisonState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      results: results ?? this.results,
      selectedStore: clearSelected ? null : (selectedStore ?? this.selectedStore),
      selectedStoreIds: selectedStoreIds ?? this.selectedStoreIds,
      storeCoordinates: storeCoordinates ?? this.storeCoordinates,
      apiTotalCost: apiTotalCost ?? this.apiTotalCost,
      stockIssues: stockIssues ?? this.stockIssues,
      trustProfile: clearTrust ? null : (trustProfile ?? this.trustProfile),
      storeRatings: storeRatings ?? this.storeRatings,
    );
  }
}

class ComparisonNotifier extends StateNotifier<ComparisonState> {
  final ComparisonRemoteDataSource _dataSource;
  final StoreRemoteDataSource _storeDataSource;
  final ExperienceRemoteDataSource _experienceDataSource;

  ComparisonNotifier(
    this._dataSource,
    this._storeDataSource,
    this._experienceDataSource,
  ) : super(const ComparisonState());

  void selectStore(Map<String, dynamic> store) {
    final storeId = (store['storeId'] as num?)?.toInt();
    state = state.copyWith(selectedStore: store);
    if (storeId != null) {
      loadTrustProfile(storeId.toString());
      loadStoreRatings(storeId);
    }
  }

  Future<void> loadStoreRatings(int storeId) async {
    try {
      final ratings = await _experienceDataSource.getStoreRatings(storeId.toString());
      state = state.copyWith(storeRatings: {...state.storeRatings, storeId: ratings});
    } catch (_) {}
  }

  void toggleStoreSelection(Map<String, dynamic> store) {
    final storeId = (store['storeId'] as num?)?.toInt();
    if (storeId == null) return;
    final updated = Set<int>.from(state.selectedStoreIds);
    if (updated.contains(storeId)) {
      updated.remove(storeId);
    } else {
      updated.add(storeId);
    }
    state = state.copyWith(selectedStoreIds: updated, selectedStore: store);
  }

  void clearSelection() {
    state = state.copyWith(clearSelected: true, selectedStoreIds: {}, clearTrust: true);
  }

  Future<void> comparePrices(int listId, {String? storeFormat}) async {
    state = state.copyWith(isLoading: true, error: null, stockIssues: []);
    try {
      await _dataSource.compareBasket(listId);
      final results = await _dataSource.comparePrices(listId, storeFormat: storeFormat);
      results.sort((a, b) {
        final costA = (a['totalCost'] as num?)?.toDouble() ?? double.infinity;
        final costB = (b['totalCost'] as num?)?.toDouble() ?? double.infinity;
        return costA.compareTo(costB);
      });

      Map<String, dynamic>? totalCostData;
      try {
        totalCostData = await _dataSource.getTotalCost(listId);
      } catch (_) {}

      state = state.copyWith(isLoading: false, results: results, apiTotalCost: totalCostData);
      await _prefetchCoordinates(results);

      if (results.isNotEmpty) {
        final firstStoreId = (results.first['storeId'] as num?)?.toInt();
        if (firstStoreId != null) {
          await verifyStock(listId, firstStoreId);
        }
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> verifyStock(int listId, int storeId) async {
    try {
      final issues = await _dataSource.verifyStock(listId, storeId);
      state = state.copyWith(stockIssues: issues);
    } catch (_) {
      state = state.copyWith(stockIssues: []);
    }
  }

  Future<void> loadTrustProfile(String storeId) async {
    try {
      final profile = await _experienceDataSource.getTrustProfile(storeId);
      state = state.copyWith(trustProfile: profile);
    } catch (_) {
      state = state.copyWith(clearTrust: true);
    }
  }

  Future<void> _prefetchCoordinates(List<Map<String, dynamic>> stores) async {
    final cache = Map<int, Map<String, double>>.from(state.storeCoordinates);
    for (var i = 0; i < stores.length; i++) {
      final store = stores[i];
      final storeId = (store['storeId'] as num?)?.toInt();
      if (storeId == null || cache.containsKey(storeId)) continue;
      cache[storeId] = await resolveStoreCoordinates(
        storeId: storeId,
        storeName: store['storeName'] as String? ?? '',
        index: i,
      );
    }
    state = state.copyWith(storeCoordinates: cache);
  }

  Future<Map<String, double>> resolveStoreCoordinates({
    required int storeId,
    required String storeName,
    required int index,
  }) async {
    if (state.storeCoordinates.containsKey(storeId)) {
      return state.storeCoordinates[storeId]!;
    }

    try {
      final profile = await _storeDataSource.getStoreProfile(storeId);
      final branches = profile['branches'] as List<dynamic>?;
      if (branches != null && branches.isNotEmpty) {
        final address = (branches.first as Map<String, dynamic>)['address'] as Map<String, dynamic>?;
        final lat = (address?['latitude'] as num?)?.toDouble();
        final lng = (address?['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          final coords = {'lat': lat, 'lng': lng};
          state = state.copyWith(storeCoordinates: {...state.storeCoordinates, storeId: coords});
          return coords;
        }
      }
    } catch (_) {}

    return _fallbackCoordinates(storeName, index);
  }

  Future<List<Map<String, dynamic>>> lookupBarcode(String barcode) {
    return _dataSource.lookupBarcode(barcode);
  }

  Future<Map<String, dynamic>> buildRouteStoreEntry(Map<String, dynamic> store, int index) async {
    final storeId = (store['storeId'] as num?)?.toInt();
    if (storeId == null) {
      throw Exception('Tienda sin ID válido');
    }

    final coords = await resolveStoreCoordinates(
      storeId: storeId,
      storeName: store['storeName'] as String? ?? 'Tienda',
      index: index,
    );

    var hasFreeParking = false;
    var isOpen24Hours = false;
    var isConvenience = false;

    try {
      final profile = await _storeDataSource.getStoreProfile(storeId);
      hasFreeParking = profile['hasFreeParking'] == true || profile['freeParking'] == true;
      isOpen24Hours = profile['open24Hours'] == true || profile['isOpen24Hours'] == true;
      final format = (profile['storeFormat'] ?? profile['format'] ?? '').toString().toLowerCase();
      isConvenience = format.contains('convenience') || format.contains('express');
    } catch (_) {}

    return {
      'storeId': storeId,
      'storeName': store['storeName'] ?? 'Tienda',
      'storeLat': coords['lat'],
      'storeLng': coords['lng'],
      'hasFreeParking': hasFreeParking,
      'isOpen24Hours': isOpen24Hours,
      'isConvenience': isConvenience,
    };
  }

  List<Map<String, dynamic>> getSelectedStores() {
    if (state.selectedStoreIds.isEmpty && state.selectedStore != null) {
      return [state.selectedStore!];
    }
    return state.results.where((s) {
      final id = (s['storeId'] as num?)?.toInt();
      return id != null && state.selectedStoreIds.contains(id);
    }).toList();
  }
}

final comparisonProvider = StateNotifierProvider<ComparisonNotifier, ComparisonState>((ref) {
  return ComparisonNotifier(
    sl<ComparisonRemoteDataSource>(),
    sl<StoreRemoteDataSource>(),
    sl<ExperienceRemoteDataSource>(),
  );
});

Map<String, double> _fallbackCoordinates(String storeName, int index) {
  final name = storeName.toLowerCase();
  double lat = -12.04318 + (index * 0.005);
  double lng = -77.02824 - (index * 0.005);

  if (name.contains('megaplaza')) {
    lat = -11.9934;
    lng = -77.0624;
  } else if (name.contains('encalada')) {
    lat = -12.1118;
    lng = -76.9723;
  } else if (name.contains('san juan')) {
    lat = -11.9833;
    lng = -76.9983;
  } else if (name.contains('listo')) {
    lat = -12.0921;
    lng = -77.0034;
  } else if (name.contains('sur') || name.contains('lima sur')) {
    lat = -12.1512 + (index * 0.001);
    lng = -76.9821;
  } else if (name.contains('vea')) {
    lat = -12.0833;
    lng = -77.0500;
  }

  return {'lat': lat, 'lng': lng};
}

Map<String, double> resolveStoreCoordinates(Map<String, dynamic> store, int index, [ComparisonState? compState]) {
  final storeId = (store['storeId'] as num?)?.toInt();
  if (storeId != null && compState != null && compState.storeCoordinates.containsKey(storeId)) {
    return compState.storeCoordinates[storeId]!;
  }
  return _fallbackCoordinates(store['storeName'] as String? ?? '', index);
}
