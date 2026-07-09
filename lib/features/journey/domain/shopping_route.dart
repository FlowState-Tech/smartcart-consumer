import 'package:equatable/equatable.dart';
import 'entities.dart';
import 'value_objects.dart';
import 'route_optimization_service.dart';

class ShoppingRoute extends Equatable {
  final Coordinates startLocation;
  final List<StopPoint> orderedStops;

  const ShoppingRoute({
    required this.startLocation,
    required this.orderedStops,
  });

  /// Factory that uses the meta-heuristic to create an optimized route.
  factory ShoppingRoute.optimized({
    required Coordinates startLocation,
    required List<StopPoint> stops,
  }) {
    final optimized = RouteOptimizationService.optimizePath(
      home: startLocation,
      unvisitedStops: stops,
    );
    return ShoppingRoute(startLocation: startLocation, orderedStops: optimized);
  }

  /// Calculates the total distance of the route
  Distance getTotalDistance() {
    if (orderedStops.isEmpty) return const Distance(0);
    
    double totalMeters = startLocation.distanceTo(orderedStops.first.coordinates);
    for (int i = 0; i < orderedStops.length - 1; i++) {
      totalMeters += orderedStops[i].coordinates.distanceTo(orderedStops[i + 1].coordinates);
    }
    return Distance(totalMeters);
  }

  @override
  List<Object?> get props => [startLocation, orderedStops];
}
