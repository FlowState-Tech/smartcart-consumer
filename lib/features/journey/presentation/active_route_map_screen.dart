import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/providers/session_providers.dart';
import '../../../core/theme/smartcart_theme.dart';
import '../../experience/application/experience_notifier.dart';
import '../../planning/application/basket_notifier.dart';
import '../application/route_notifier.dart';
import '../application/route_state.dart';
import 'widgets/store_compass_widget.dart';

class ActiveRouteMapScreen extends ConsumerStatefulWidget {
  final VoidCallback? onJourneyFinished;

  const ActiveRouteMapScreen({super.key, this.onJourneyFinished});

  @override
  ConsumerState<ActiveRouteMapScreen> createState() => _ActiveRouteMapScreenState();
}

class _ActiveRouteMapScreenState extends ConsumerState<ActiveRouteMapScreen> {
  GoogleMapController? _mapController;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (ref.read(routeProvider).isNavigating) {
        ref.read(routeProvider.notifier).updateUserLocation();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final buyerId = ref.read(currentBuyerIdProvider);
      ref.read(routeProvider.notifier).loadRouteHistory(buyerId);
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _fitMapToRoute(RouteState routeState) {
    if (_mapController == null) return;

    final points = <LatLng>[];
    if (routeState.userLocation != null) {
      points.add(LatLng(routeState.userLocation!.latitude, routeState.userLocation!.longitude));
    }
    points.addAll(routeState.polylinePoints);

    if (routeState.activeRoute?.orderedStops.isNotEmpty == true) {
      for (final stop in routeState.activeRoute!.orderedStops) {
        points.add(LatLng(stop.coordinates.latitude, stop.coordinates.longitude));
      }
    }

    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(points.first, 14));
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final p in points) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }

  Set<Marker> _buildMarkers(RouteState routeState) {
    final markers = <Marker>{};

    if (routeState.userLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('user'),
        position: LatLng(routeState.userLocation!.latitude, routeState.userLocation!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Tu ubicación'),
      ));
    }

    final stops = routeState.activeRoute?.orderedStops ?? [];
    for (var i = 0; i < stops.length; i++) {
      final stop = stops[i];
      markers.add(Marker(
        markerId: MarkerId('stop_${stop.id}'),
        position: LatLng(stop.coordinates.latitude, stop.coordinates.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(title: stop.name),
      ));
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(RouteState routeState) {
    if (routeState.polylinePoints.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: routeState.polylinePoints,
        color: SmartCartTheme.primaryColor,
        width: 5,
      ),
    };
  }

  Future<void> _onArrived() async {
    final ok = await ref.read(routeProvider.notifier).registerArrival();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Llegada registrada! Ya puedes validar tu compra.')),
      );
    } else {
      final err = ref.read(routeProvider).errorMessage;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  Future<void> _onFinish() async {
    final routeState = ref.read(routeProvider);
    final ok = await ref.read(routeProvider.notifier).finishJourney();
    if (!mounted) return;

    if (ok && routeState.routeId != null && routeState.destinationStoreId != null) {
      final stop = routeState.nextTarget ?? routeState.activeRoute?.orderedStops.firstOrNull;
      ref.read(experienceProvider.notifier).setJourneyContext(
            recorridoId: routeState.routeId!,
            storeId: routeState.destinationStoreId.toString(),
            storeName: routeState.destinationStoreName ?? stop?.name ?? 'Tienda',
            storeLat: stop?.coordinates.latitude,
            storeLng: stop?.coordinates.longitude,
          );
      await ref.read(experienceProvider.notifier).recordPurchase();
      widget.onJourneyFinished?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recorrido finalizado. Ve a Validar para confirmar y opinar.')),
      );
    } else {
      final err = ref.read(routeProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'No se pudo finalizar el recorrido')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeState = ref.watch(routeProvider);
    final basketState = ref.watch(basketProvider);
    final items = basketState.shoppingList.items;

    ref.listen<RouteState>(routeProvider, (prev, next) {
      if (next.polylinePoints.isNotEmpty && prev?.polylinePoints != next.polylinePoints) {
        _fitMapToRoute(next);
      }
    });

    final storeName = routeState.destinationStoreName ??
        routeState.activeRoute?.orderedStops.firstOrNull?.name ??
        'Selecciona una tienda en Comparar';

    final initialTarget = routeState.userLocation != null
        ? LatLng(routeState.userLocation!.latitude, routeState.userLocation!.longitude)
        : const LatLng(-12.04318, -77.02824);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: SmartCartTheme.primaryColor,
        elevation: 0,
        title: const Text('Ruta de compra', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => _showRouteHistory(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initialTarget, zoom: 13),
            onMapCreated: (controller) {
              _mapController = controller;
              _fitMapToRoute(routeState);
            },
            markers: _buildMarkers(routeState),
            polylines: _buildPolylines(routeState),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),
          if (routeState.isLoading)
            const ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),
          if (routeState.nextTarget != null && routeState.userLocation != null && routeState.isNavigating)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: StoreCompassWidget(
                        userLocation: routeState.userLocation!,
                        targetStop: routeState.nextTarget!,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Conveniencia'),
                          selected: routeState.filterConvenienceOnly,
                          onSelected: (_) {
                            if (routeState.userLocation != null) {
                              ref.read(routeProvider.notifier).toggleFilterConvenience(routeState.userLocation!);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('24h'),
                          selected: routeState.filterOpen24Hours,
                          onSelected: (_) {
                            if (routeState.userLocation != null) {
                              ref.read(routeProvider.notifier).toggleFilter24Hours(routeState.userLocation!);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Parking'),
                          selected: routeState.filterFreeParking,
                          onSelected: (_) {
                            if (routeState.userLocation != null) {
                              ref.read(routeProvider.notifier).toggleFilterFreeParking(routeState.userLocation!);
                            }
                          },
                        ),
                        if (routeState.multiStopStoreIds.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Chip(
                              label: Text('${routeState.multiStopStoreIds.length} paradas'),
                              backgroundColor: SmartCartTheme.primaryColor.withOpacity(0.2),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.42),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: SmartCartTheme.primaryColor.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).colorScheme.surfaceVariant,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.store, color: SmartCartTheme.primaryColor, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(storeName,
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                        fontWeight: FontWeight.bold)),
                                if (routeState.distanceMeters != null)
                                  Text(
                                    '${(routeState.distanceMeters! / 1000).toStringAsFixed(1)} km · ${routeState.durationSeconds != null ? '${(routeState.durationSeconds! / 60).round()} min' : ''}',
                                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                                  )
                                else
                                  Text(
                                    routeState.isNavigating ? 'Navegación activa' : 'Elige una tienda en Comparar',
                                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                                  ),
                              ],
                            ),
                          ),
                          if (routeState.hasArrived)
                            const Chip(
                              label: Text('En tienda', style: TextStyle(color: Colors.white, fontSize: 11)),
                              backgroundColor: Colors.teal,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (routeState.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(routeState.errorMessage!, style: const TextStyle(color: Colors.red)),
                    ),
                  const Divider(height: 1),
                  Flexible(
                    child: items.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('No hay productos en la ruta',
                                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: items.length,
                            itemBuilder: (ctx, index) {
                              final item = items[index];
                              final checked = routeState.checkedItemSkus.contains(item.id);
                              return Column(
                                children: [
                                  ListTile(
                                    leading: IconButton(
                                      icon: Icon(checked ? Icons.check_box : Icons.check_box_outline_blank,
                                          color: SmartCartTheme.primaryColor),
                                      onPressed: () => ref.read(routeProvider.notifier).toggleItemChecked(item.id),
                                    ),
                                    title: Text(item.name, style: checked ? const TextStyle(decoration: TextDecoration.lineThrough) : null),
                                    subtitle: Text('S/ ${item.price.toStringAsFixed(2)}'),
                                  ),
                                  const Divider(height: 1),
                                ],
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: routeState.isNavigating && !routeState.isLoading ? _onArrived : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.tealAccent.shade400,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Llegué', style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: (routeState.isNavigating || routeState.hasArrived) && !routeState.isLoading
                                ? _onFinish
                                : null,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Finalizar', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRouteHistory(BuildContext context) {
    final history = ref.read(routeProvider).routeHistory;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Historial de rutas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            if (history.isEmpty)
              const Padding(padding: EdgeInsets.all(16), child: Text('Sin rutas anteriores'))
            else
              ...history.take(10).map((route) {
                final id = route['id']?.toString() ?? '';
                return ListTile(
                  title: Text('Ruta $id'),
                  subtitle: Text('Estado: ${route['status'] ?? 'desconocido'}'),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(routeProvider.notifier).resumeRoute(id, userLocation: ref.read(routeProvider).userLocation);
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}
