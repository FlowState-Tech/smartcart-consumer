import 'package:equatable/equatable.dart';
import '../domain/shopping_route.dart';
import '../domain/entities.dart';

class RouteState extends Equatable {
  final ShoppingRoute? activeRoute;
  final StopPoint? nextTarget;
  final List<StopPoint> allStops;
  
  // Filters
  final bool filterConvenienceOnly;
  final bool filterOpen24Hours;
  final bool filterFreeParking;

  const RouteState({
    this.activeRoute,
    this.nextTarget,
    this.allStops = const [],
    this.filterConvenienceOnly = false,
    this.filterOpen24Hours = false,
    this.filterFreeParking = false,
  });

  RouteState copyWith({
    ShoppingRoute? activeRoute,
    StopPoint? nextTarget,
    List<StopPoint>? allStops,
    bool? filterConvenienceOnly,
    bool? filterOpen24Hours,
    bool? filterFreeParking,
  }) {
    return RouteState(
      activeRoute: activeRoute ?? this.activeRoute,
      nextTarget: nextTarget ?? this.nextTarget,
      allStops: allStops ?? this.allStops,
      filterConvenienceOnly: filterConvenienceOnly ?? this.filterConvenienceOnly,
      filterOpen24Hours: filterOpen24Hours ?? this.filterOpen24Hours,
      filterFreeParking: filterFreeParking ?? this.filterFreeParking,
    );
  }

  @override
  List<Object?> get props => [
        activeRoute,
        nextTarget,
        allStops,
        filterConvenienceOnly,
        filterOpen24Hours,
        filterFreeParking,
      ];
}
