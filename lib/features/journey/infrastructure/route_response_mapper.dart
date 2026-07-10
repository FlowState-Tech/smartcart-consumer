import '../domain/entities.dart';
import '../domain/value_objects.dart';

class RouteResponseMapper {
  static String extractRouteId(Map<String, dynamic> data) {
    return (data['routeId'] ?? data['id'] ?? '').toString();
  }

  static List<StopPoint> parseStops(Map<String, dynamic> data) {
    final stopsRaw = data['stops'] as List<dynamic>? ?? [];
    return stopsRaw.map((stop) {
      final s = stop as Map<String, dynamic>;
      return StopPoint(
        id: (s['storeId'] ?? '').toString(),
        name: s['storeName'] as String? ?? 'Tienda',
        coordinates: Coordinates(
          latitude: (s['latitude'] as num?)?.toDouble() ?? 0,
          longitude: (s['longitude'] as num?)?.toDouble() ?? 0,
        ),
        isConvenience: false,
        isOpen24Hours: false,
        hasFreeParking: false,
        crowdLevel: CrowdLevel.media,
      );
    }).toList();
  }

  static Coordinates? parseResidence(Map<String, dynamic> data) {
    final lat = (data['residenceLat'] as num?)?.toDouble();
    final lng = (data['residenceLng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return Coordinates(latitude: lat, longitude: lng);
  }
}
