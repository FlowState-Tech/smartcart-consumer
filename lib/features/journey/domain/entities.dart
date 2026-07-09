import 'package:equatable/equatable.dart';
import 'value_objects.dart';

enum CrowdLevel { baja, media, alta }

class StopPoint extends Equatable {
  final String id;
  final String name;
  final Coordinates coordinates;
  
  // Filtering flags
  final bool isConvenience;
  final bool isOpen24Hours;
  final bool hasFreeParking;
  
  // Community Tracker
  final CrowdLevel crowdLevel;

  const StopPoint({
    required this.id,
    required this.name,
    required this.coordinates,
    required this.isConvenience,
    required this.isOpen24Hours,
    required this.hasFreeParking,
    required this.crowdLevel,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        coordinates,
        isConvenience,
        isOpen24Hours,
        hasFreeParking,
        crowdLevel,
      ];
}
