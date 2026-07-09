import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/value_objects.dart';
import '../domain/entities.dart';
import '../domain/shopping_route.dart';
import '../../../core/di/injection_container.dart';
import '../infrastructure/shopping_journey_remote_data_source.dart';
import 'route_state.dart';

class RouteNotifier extends StateNotifier<RouteState> {
  final ShoppingJourneyRemoteDataSource _dataSource;
  
  RouteNotifier(this._dataSource) : super(const RouteState());

  Future<void> createBackendRoute(int buyerId, int listId) async {
    try {
      final routeData = await _dataSource.createRoute(buyerId, listId);
      // Depending on response, we might parse stops from routeData and call setStops
      // For now, we just notify that creation succeeded.
      print('Route created: ' + routeData["id"].toString());
    } catch (e) {
      print('Error creating backend route: $e');
    }
  }

  void setStops(List<StopPoint> stops, Coordinates userLocation) {
    state = state.copyWith(allStops: stops);
    _recalculateRoute(userLocation);
  }

  void toggleFilterConvenience(Coordinates userLocation) {
    state = state.copyWith(filterConvenienceOnly: !state.filterConvenienceOnly);
    _recalculateRoute(userLocation);
  }

  void toggleFilter24Hours(Coordinates userLocation) {
    state = state.copyWith(filterOpen24Hours: !state.filterOpen24Hours);
    _recalculateRoute(userLocation);
  }

  void toggleFilterFreeParking(Coordinates userLocation) {
    state = state.copyWith(filterFreeParking: !state.filterFreeParking);
    _recalculateRoute(userLocation);
  }

  void updateNextTarget(StopPoint stop) {
    state = state.copyWith(nextTarget: stop);
  }

  void _recalculateRoute(Coordinates userLocation) {
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

    final newRoute = ShoppingRoute.optimized(
      startLocation: userLocation,
      stops: filteredStops,
    );

    state = state.copyWith(
      activeRoute: newRoute,
      nextTarget: newRoute.orderedStops.isNotEmpty ? newRoute.orderedStops.first : null,
    );
  }
}

final routeProvider = StateNotifierProvider<RouteNotifier, RouteState>((ref) {
  return RouteNotifier(sl<ShoppingJourneyRemoteDataSource>());
});
