import 'value_objects.dart';
import 'entities.dart';

class RouteOptimizationService {
  /// Meta-heuristic helper: Nearest Neighbor approximation.
  /// Sorts a list of [StopPoint]s to minimize total path distance starting from [home].
  static List<StopPoint> optimizePath({
    required Coordinates home,
    required List<StopPoint> unvisitedStops,
  }) {
    if (unvisitedStops.isEmpty) return [];
    
    final List<StopPoint> optimizedPath = [];
    final List<StopPoint> remainingStops = List.from(unvisitedStops);
    Coordinates currentLocation = home;

    while (remainingStops.isNotEmpty) {
      // Find the nearest unvisited stop
      StopPoint nearestStop = remainingStops.first;
      double minDistance = currentLocation.distanceTo(nearestStop.coordinates);

      for (int i = 1; i < remainingStops.length; i++) {
        final stop = remainingStops[i];
        final distance = currentLocation.distanceTo(stop.coordinates);
        if (distance < minDistance) {
          minDistance = distance;
          nearestStop = stop;
        }
      }

      // Add to path and update current location
      optimizedPath.add(nearestStop);
      remainingStops.remove(nearestStop);
      currentLocation = nearestStop.coordinates;
    }

    return optimizedPath;
  }
}
