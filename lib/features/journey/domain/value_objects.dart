import 'package:equatable/equatable.dart';
import 'dart:math' as math;

class Coordinates extends Equatable {
  final double latitude;
  final double longitude;

  const Coordinates({required this.latitude, required this.longitude});

  // Calculate Haversine distance in meters without relying on flutter plugins in the domain
  double distanceTo(Coordinates other) {
    const double earthRadius = 6371000; // in meters
    final double dLat = _toRadians(other.latitude - latitude);
    final double dLon = _toRadians(other.longitude - longitude);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(other.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
            
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  // Calculate bearing in degrees
  double bearingTo(Coordinates other) {
    final double lat1 = _toRadians(latitude);
    final double lon1 = _toRadians(longitude);
    final double lat2 = _toRadians(other.latitude);
    final double lon2 = _toRadians(other.longitude);

    final double dLon = lon2 - lon1;

    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    double bearing = math.atan2(y, x);
    bearing = _toDegrees(bearing);
    return (bearing + 360) % 360;
  }

  static double _toRadians(double degree) => degree * math.pi / 180;
  static double _toDegrees(double radian) => radian * 180 / math.pi;

  @override
  List<Object?> get props => [latitude, longitude];
}

class Distance extends Equatable {
  final double meters;

  const Distance(this.meters);

  String toFormattedString() {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  @override
  List<Object?> get props => [meters];
}
