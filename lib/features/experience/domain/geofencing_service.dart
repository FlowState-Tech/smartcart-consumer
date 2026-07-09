import 'dart:math' as math;

class GeofencingService {
  /// Validates if the user is within a 500-meter radius of the target location.
  static bool isWithinStoreRadius(
    double userLat, 
    double userLng, 
    double storeLat, 
    double storeLng
  ) {
    const double earthRadius = 6371000; // in meters
    final double dLat = _toRadians(storeLat - userLat);
    final double dLon = _toRadians(storeLng - userLng);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(userLat)) *
            math.cos(_toRadians(storeLat)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
            
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final double distanceInMeters = earthRadius * c;
    
    return distanceInMeters <= 500.0;
  }

  static double _toRadians(double degree) => degree * math.pi / 180;
}
