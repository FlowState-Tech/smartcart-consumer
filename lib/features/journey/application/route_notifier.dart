import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/utils/polyline_decoder.dart';
import '../../planning/infrastructure/comparison_remote_data_source.dart';
import '../../planning/infrastructure/preferences_remote_data_source.dart';
import '../domain/entities.dart';
import '../domain/shopping_route.dart';
import '../domain/value_objects.dart';
import '../infrastructure/route_response_mapper.dart';
import '../infrastructure/shopping_journey_remote_data_source.dart';
import 'route_state.dart';

class RouteNotifier extends StateNotifier<RouteState> {
  final ShoppingJourneyRemoteDataSource _dataSource;
  final ComparisonRemoteDataSource _comparisonDataSource;
  final PreferencesRemoteDataSource _preferencesDataSource;

  RouteNotifier(
    this._dataSource,
    this._comparisonDataSource,
    this._preferencesDataSource,
  ) : super(const RouteState());

  Future<Coordinates?> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition();
    return Coordinates(latitude: position.latitude, longitude: position.longitude);
  }

  Future<void> _saveResidencePreference(int buyerId, Coordinates origin) async {
    try {
      await _preferencesDataSource.updatePreferences(buyerId, {
        'homeLatitude': origin.latitude,
        'homeLongitude': origin.longitude,
      });
    } catch (_) {}
  }

  Future<bool> startMultiStopRoute({
    required int buyerId,
    required int listId,
    required List<Map<String, dynamic>> stores,
  }) {
    if (stores.isEmpty) return Future.value(false);
    return _startRoute(buyerId: buyerId, listId: listId, stores: stores);
  }

  Future<bool> _startRoute({
    required int buyerId,
    required int listId,
    required List<Map<String, dynamic>> stores,
  }) async {
    state = state.copyWith(status: RouteStatus.loading, clearError: true, visitedStopIds: {}, currentStopIndex: 0);

    try {
      try {
        await _comparisonDataSource.compareBasket(listId);
      } catch (_) {}

      final userLocation = await _getCurrentLocation();
      final origin = userLocation ?? const Coordinates(latitude: -12.04318, longitude: -77.02824);

      final created = await _dataSource.createRoute(buyerId, listId);
      final routeId = RouteResponseMapper.extractRouteId(created);
      if (routeId.isEmpty) throw Exception('El backend no devolvió un ID de ruta');

      await _dataSource.defineResidence(routeId, origin.latitude, origin.longitude);
      await _saveResidencePreference(buyerId, origin);

      final storeIds = stores.map((s) => (s['storeId'] as num?)?.toInt()).whereType<int>().toList();
      if (storeIds.isEmpty) throw Exception('No hay tiendas válidas en la ruta');

      Map<String, dynamic> routeData = await _dataSource.selectDestination(routeId, storeIds.first);

      if (storeIds.length > 1) {
        try {
          routeData = await _dataSource.optimizeRoute(routeId, storeIds);
        } catch (_) {}
      }

      try {
        routeData = await _dataSource.requestPath(routeId);
      } catch (_) {
        try {
          routeData = await _dataSource.getOptimalView(routeId);
        } catch (_) {}
      }

      routeData = await _dataSource.startNavigation(routeId);

      final fallbackStops = stores.map((s) => _stopFromStoreMap(s)).toList();

      _applyRouteResponse(
        routeData,
        routeId: routeId,
        userLocation: origin,
        fallbackStops: fallbackStops,
      );

      final primary = stores.first;
      state = state.copyWith(
        status: RouteStatus.navigating,
        destinationStoreId: (primary['storeId'] as num?)?.toInt(),
        destinationStoreName: primary['storeName'] as String? ?? 'Tienda',
        multiStopStoreIds: storeIds,
        currentStopIndex: 0,
        allStopsVisited: storeIds.length <= 1,
      );
      return true;
    } catch (e) {
      state = state.copyWith(status: RouteStatus.error, errorMessage: e.toString());
      return false;
    }
  }

  StopPoint _stopFromStoreMap(Map<String, dynamic> s) {
    return StopPoint(
      id: (s['storeId'] ?? '').toString(),
      name: s['storeName'] as String? ?? 'Tienda',
      coordinates: Coordinates(
        latitude: (s['storeLat'] as num?)?.toDouble() ?? -12.05,
        longitude: (s['storeLng'] as num?)?.toDouble() ?? -77.03,
      ),
      isConvenience: s['isConvenience'] == true ||
          (s['storeName'] as String? ?? '').toLowerCase().contains('tambo') ||
          (s['storeName'] as String? ?? '').toLowerCase().contains('oxxo'),
      isOpen24Hours: s['isOpen24Hours'] == true ||
          (s['storeName'] as String? ?? '').toLowerCase().contains('24h') ||
          (s['storeName'] as String? ?? '').toLowerCase().contains('listo'),
      hasFreeParking: s['hasFreeParking'] == true,
      crowdLevel: CrowdLevel.media,
    );
  }

  Future<void> loadRouteHistory(int buyerId, {int? listId}) async {
    try {
      final routes = await _dataSource.findRoutes(buyerId, listId: listId);
      state = state.copyWith(routeHistory: routes);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<bool> resumeRoute(String routeId, {required Coordinates? userLocation}) async {
    state = state.copyWith(status: RouteStatus.loading, clearError: true);
    try {
      var routeData = await _dataSource.getRoute(routeId);
      try {
        routeData = await _dataSource.getOptimalView(routeId);
      } catch (_) {}
      try {
        routeData = await _dataSource.startNavigation(routeId);
      } catch (_) {}

      final origin = userLocation ?? await _getCurrentLocation() ?? const Coordinates(latitude: -12.04318, longitude: -77.02824);
      _applyRouteResponse(routeData, routeId: routeId, userLocation: origin, fallbackStops: RouteResponseMapper.parseStops(routeData));

      state = state.copyWith(status: RouteStatus.navigating);
      return true;
    } catch (e) {
      state = state.copyWith(status: RouteStatus.error, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> updateUserLocation() async {
    final location = await _getCurrentLocation();
    if (location == null) return;
    state = state.copyWith(userLocation: location);
    if (state.allStops.isNotEmpty) {
      _recalculateLocalRoute(location);
    }
  }

  Future<bool> registerArrival() async {
    final routeId = state.routeId;
    if (routeId == null) return false;

    state = state.copyWith(status: RouteStatus.loading, clearError: true);
    try {
      final location = await _getCurrentLocation();
      if (location == null) {
        throw Exception('Activa el GPS para registrar tu llegada');
      }

      await _dataSource.registerArrival(routeId, location.latitude, location.longitude);

      final visited = Set<String>.from(state.visitedStopIds);
      if (state.nextTarget != null) {
        visited.add(state.nextTarget!.id);
      }

      final remaining = state.allStops.where((s) => !visited.contains(s.id)).toList();

      if (remaining.isNotEmpty) {
        final nextStop = remaining.first;
        final nextStoreId = int.tryParse(nextStop.id);

        if (nextStoreId != null) {
          try {
            var routeData = await _dataSource.selectDestination(routeId, nextStoreId);
            try {
              routeData = await _dataSource.requestPath(routeId);
            } catch (_) {
              try {
                routeData = await _dataSource.getOptimalView(routeId);
              } catch (_) {}
            }
            _applyRouteResponse(
              routeData,
              routeId: routeId,
              userLocation: location,
              fallbackStops: state.allStops,
            );
          } catch (_) {}
        }

        state = state.copyWith(
          status: RouteStatus.navigating,
          hasArrived: false,
          allStopsVisited: false,
          visitedStopIds: visited,
          nextTarget: nextStop,
          destinationStoreId: nextStoreId,
          destinationStoreName: nextStop.name,
          currentStopIndex: state.currentStopIndex + 1,
          userLocation: location,
        );
      } else {
        state = state.copyWith(
          status: RouteStatus.arrived,
          hasArrived: true,
          allStopsVisited: true,
          visitedStopIds: visited,
          userLocation: location,
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(status: RouteStatus.navigating, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> finishJourney() async {
    final routeId = state.routeId;
    if (routeId == null) return false;

    if (state.multiStopStoreIds.length > 1 && !state.allStopsVisited) {
      state = state.copyWith(errorMessage: 'Visita todas las paradas antes de finalizar');
      return false;
    }

    state = state.copyWith(status: RouteStatus.loading, clearError: true);
    try {
      await _dataSource.finishJourney(routeId);
      state = state.copyWith(status: RouteStatus.finished);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: state.hasArrived ? RouteStatus.arrived : RouteStatus.navigating,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void toggleItemChecked(String sku) {
    final updated = Set<String>.from(state.checkedItemSkus);
    if (updated.contains(sku)) {
      updated.remove(sku);
    } else {
      updated.add(sku);
    }
    state = state.copyWith(checkedItemSkus: updated);
  }

  void setStops(List<StopPoint> stops, Coordinates userLocation) {
    state = state.copyWith(allStops: stops, userLocation: userLocation);
    _recalculateLocalRoute(userLocation);
  }

  void toggleFilterConvenience(Coordinates userLocation) {
    state = state.copyWith(filterConvenienceOnly: !state.filterConvenienceOnly);
    _recalculateLocalRoute(userLocation);
  }

  void toggleFilter24Hours(Coordinates userLocation) {
    state = state.copyWith(filterOpen24Hours: !state.filterOpen24Hours);
    _recalculateLocalRoute(userLocation);
  }

  void toggleFilterFreeParking(Coordinates userLocation) {
    state = state.copyWith(filterFreeParking: !state.filterFreeParking);
    _recalculateLocalRoute(userLocation);
  }

  void _recalculateLocalRoute(Coordinates userLocation) {
    var filteredStops = state.allStops;
    if (state.filterConvenienceOnly) {
      filteredStops = filteredStops.where((s) => s.isConvenience).toList();
    }
    if (state.filterOpen24Hours) {
      filteredStops = filteredStops.where((s) => s.isOpen24Hours).toList();
    }
    if (state.filterFreeParking) {
      filteredStops = filteredStops.where((s) => s.hasFreeParking).toList();
    }

    if (filteredStops.isEmpty) {
      state = state.copyWith(errorMessage: 'Ninguna parada cumple los filtros activos', nextTarget: null);
      return;
    }

    final unvisited = filteredStops.where((s) => !state.visitedStopIds.contains(s.id)).toList();
    final targetPool = unvisited.isNotEmpty ? unvisited : filteredStops;

    final newRoute = ShoppingRoute.optimized(startLocation: userLocation, stops: filteredStops);

    state = state.copyWith(
      activeRoute: newRoute,
      nextTarget: targetPool.first,
      clearError: true,
    );
  }

  void _applyRouteResponse(
    Map<String, dynamic> data, {
    required String routeId,
    required Coordinates userLocation,
    required List<StopPoint> fallbackStops,
  }) {
    var stops = RouteResponseMapper.parseStops(data);
    if (stops.isEmpty) stops = fallbackStops;

    final encoded = data['encodedPolyline'] as String? ?? '';
    final polylinePoints = encoded.isNotEmpty ? PolylineDecoder.decode(encoded) : <LatLng>[];

    final activeRoute = ShoppingRoute.optimized(startLocation: userLocation, stops: stops);
    final unvisited = stops.where((s) => !state.visitedStopIds.contains(s.id)).toList();

    state = state.copyWith(
      routeId: routeId,
      activeRoute: activeRoute,
      nextTarget: unvisited.isNotEmpty ? unvisited.first : (stops.isNotEmpty ? stops.first : null),
      allStops: stops,
      userLocation: userLocation,
      encodedPolyline: encoded,
      polylinePoints: polylinePoints,
      distanceMeters: (data['distanceMeters'] as num?)?.toInt(),
      durationSeconds: (data['durationSeconds'] as num?)?.toInt(),
    );
  }

  void resetRoute() {
    state = const RouteState();
  }
}

final routeProvider = StateNotifierProvider<RouteNotifier, RouteState>((ref) {
  return RouteNotifier(
    sl<ShoppingJourneyRemoteDataSource>(),
    sl<ComparisonRemoteDataSource>(),
    sl<PreferencesRemoteDataSource>(),
  );
});
