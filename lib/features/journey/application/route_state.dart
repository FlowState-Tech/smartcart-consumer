import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../domain/shopping_route.dart';
import '../domain/entities.dart';
import '../domain/value_objects.dart';

enum RouteStatus { idle, loading, navigating, arrived, finished, error }

class RouteState extends Equatable {
  final RouteStatus status;
  final String? routeId;
  final String? errorMessage;
  final ShoppingRoute? activeRoute;
  final StopPoint? nextTarget;
  final List<StopPoint> allStops;
  final Coordinates? userLocation;
  final String? encodedPolyline;
  final List<LatLng> polylinePoints;
  final int? distanceMeters;
  final int? durationSeconds;
  final int? destinationStoreId;
  final String? destinationStoreName;
  final bool hasArrived;
  final bool allStopsVisited;
  final bool filterConvenienceOnly;
  final bool filterOpen24Hours;
  final bool filterFreeParking;
  final List<int> multiStopStoreIds;
  final int currentStopIndex;
  final Set<String> visitedStopIds;
  final Set<String> checkedItemSkus;
  final List<Map<String, dynamic>> routeHistory;

  const RouteState({
    this.status = RouteStatus.idle,
    this.routeId,
    this.errorMessage,
    this.activeRoute,
    this.nextTarget,
    this.allStops = const [],
    this.userLocation,
    this.encodedPolyline,
    this.polylinePoints = const [],
    this.distanceMeters,
    this.durationSeconds,
    this.destinationStoreId,
    this.destinationStoreName,
    this.hasArrived = false,
    this.allStopsVisited = false,
    this.filterConvenienceOnly = false,
    this.filterOpen24Hours = false,
    this.filterFreeParking = false,
    this.multiStopStoreIds = const [],
    this.currentStopIndex = 0,
    this.visitedStopIds = const {},
    this.checkedItemSkus = const {},
    this.routeHistory = const [],
  });

  bool get isLoading => status == RouteStatus.loading;
  bool get isNavigating => status == RouteStatus.navigating;
  bool get isFinished => status == RouteStatus.finished;

  RouteState copyWith({
    RouteStatus? status,
    String? routeId,
    String? errorMessage,
    ShoppingRoute? activeRoute,
    StopPoint? nextTarget,
    List<StopPoint>? allStops,
    Coordinates? userLocation,
    String? encodedPolyline,
    List<LatLng>? polylinePoints,
    int? distanceMeters,
    int? durationSeconds,
    int? destinationStoreId,
    String? destinationStoreName,
    bool? hasArrived,
    bool? allStopsVisited,
    bool? filterConvenienceOnly,
    bool? filterOpen24Hours,
    bool? filterFreeParking,
    List<int>? multiStopStoreIds,
    int? currentStopIndex,
    Set<String>? visitedStopIds,
    Set<String>? checkedItemSkus,
    List<Map<String, dynamic>>? routeHistory,
    bool clearError = false,
  }) {
    return RouteState(
      status: status ?? this.status,
      routeId: routeId ?? this.routeId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeRoute: activeRoute ?? this.activeRoute,
      nextTarget: nextTarget ?? this.nextTarget,
      allStops: allStops ?? this.allStops,
      userLocation: userLocation ?? this.userLocation,
      encodedPolyline: encodedPolyline ?? this.encodedPolyline,
      polylinePoints: polylinePoints ?? this.polylinePoints,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      destinationStoreId: destinationStoreId ?? this.destinationStoreId,
      destinationStoreName: destinationStoreName ?? this.destinationStoreName,
      hasArrived: hasArrived ?? this.hasArrived,
      allStopsVisited: allStopsVisited ?? this.allStopsVisited,
      filterConvenienceOnly: filterConvenienceOnly ?? this.filterConvenienceOnly,
      filterOpen24Hours: filterOpen24Hours ?? this.filterOpen24Hours,
      filterFreeParking: filterFreeParking ?? this.filterFreeParking,
      multiStopStoreIds: multiStopStoreIds ?? this.multiStopStoreIds,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      visitedStopIds: visitedStopIds ?? this.visitedStopIds,
      checkedItemSkus: checkedItemSkus ?? this.checkedItemSkus,
      routeHistory: routeHistory ?? this.routeHistory,
    );
  }

  @override
  List<Object?> get props => [
        status,
        routeId,
        errorMessage,
        activeRoute,
        nextTarget,
        allStops,
        userLocation,
        encodedPolyline,
        polylinePoints,
        distanceMeters,
        durationSeconds,
        destinationStoreId,
        destinationStoreName,
        hasArrived,
        allStopsVisited,
        filterConvenienceOnly,
        filterOpen24Hours,
        filterFreeParking,
        multiStopStoreIds,
        currentStopIndex,
        visitedStopIds,
        checkedItemSkus,
        routeHistory,
      ];
}
