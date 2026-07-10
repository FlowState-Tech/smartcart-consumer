import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/session_providers.dart';
import '../../../core/theme/smartcart_theme.dart';
import '../application/basket_notifier.dart';
import '../application/comparison_notifier.dart';
import '../../journey/application/route_notifier.dart';

class ComparadorScreen extends ConsumerStatefulWidget {
  final void Function(int tabIndex)? onNavigate;

  const ComparadorScreen({super.key, this.onNavigate});

  @override
  ConsumerState<ComparadorScreen> createState() => _ComparadorScreenState();
}

class _ComparadorScreenState extends ConsumerState<ComparadorScreen> {
  String _selectedFilter = 'Todas';
  double? _userLat;
  double? _userLng;
  bool _multiSelectMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
        });
      }
    } catch (_) {}
  }

  String? _filterFormat(String filter) {
    switch (filter) {
      case 'Supermercados':
        return 'supermarket';
      case 'Conveniencia':
        return 'convenience';
      default:
        return null;
    }
  }

  List<Map<String, dynamic>> _filteredStores(List<Map<String, dynamic>> stores) {
    if (_selectedFilter == 'Supermercados') {
      return stores
          .where((s) =>
              s['storeName'].toString().toLowerCase().contains('vea') ||
              s['storeName'].toString().toLowerCase().contains('metro') ||
              s['storeName'].toString().toLowerCase().contains('wong') ||
              s['storeName'].toString().toLowerCase().contains('tottus') ||
              s['storeName'].toString().toLowerCase().contains('super'))
          .toList();
    }
    if (_selectedFilter == 'Conveniencia') {
      return stores
          .where((s) =>
              s['storeName'].toString().toLowerCase().contains('tambo') ||
              s['storeName'].toString().toLowerCase().contains('oxxo') ||
              s['storeName'].toString().toLowerCase().contains('mass'))
          .toList();
    }
    if (_selectedFilter == '24h') {
      return stores
          .where((s) =>
              s['storeName'].toString().toLowerCase().contains('24h') ||
              s['storeName'].toString().toLowerCase().contains('listo'))
          .toList();
    }
    return stores;
  }

  Future<void> _startRouteToSelectedStore() async {
    final compState = ref.read(comparisonProvider);
    final listId = ref.read(basketProvider).remoteListId;
    final buyerId = ref.read(currentBuyerIdProvider);

    if (listId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega productos a tu canasta antes de crear una ruta')),
      );
      return;
    }

    if (_multiSelectMode && compState.selectedStoreIds.length > 1) {
      final selectedStores = await _buildMultiStopPayload(compState);
      final ok = await ref.read(routeProvider.notifier).startMultiStopRoute(
            buyerId: buyerId,
            listId: listId,
            stores: selectedStores,
          );
      if (!mounted) return;
      if (ok) {
        widget.onNavigate?.call(2);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ruta multi-parada con ${selectedStores.length} tiendas creada')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(routeProvider).errorMessage ?? 'Error al crear ruta')),
        );
      }
      return;
    }

    final selected = compState.selectedStore;
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una tienda de la lista primero')),
      );
      return;
    }

    final storeId = (selected['storeId'] as num?)?.toInt();
    if (storeId == null) return;

    final index = compState.results.indexOf(selected);
    final storeEntry = await ref.read(comparisonProvider.notifier).buildRouteStoreEntry(
          selected,
          index >= 0 ? index : 0,
        );

    ref.read(basketProvider.notifier).checkSubstitutesForStore(storeId);

    final ok = await ref.read(routeProvider.notifier).startMultiStopRoute(
          buyerId: buyerId,
          listId: listId,
          stores: [storeEntry],
        );

    if (!mounted) return;

    if (ok) {
      widget.onNavigate?.call(2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ruta hacia ${selected['storeName']} creada')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(routeProvider).errorMessage ?? 'Error al crear ruta')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _buildMultiStopPayload(ComparisonState compState) async {
    final stores = compState.results.where((s) {
      final id = (s['storeId'] as num?)?.toInt();
      return id != null && compState.selectedStoreIds.contains(id);
    }).toList();

    final payload = <Map<String, dynamic>>[];
    for (var i = 0; i < stores.length; i++) {
      payload.add(await ref.read(comparisonProvider.notifier).buildRouteStoreEntry(stores[i], i));
    }
    return payload;
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return earthRadius * 2 * math.asin(math.sqrt(a));
  }

  double _toRad(double deg) => deg * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    final basketState = ref.watch(basketProvider);
    final compState = ref.watch(comparisonProvider);

    ref.listen<ComparisonState>(comparisonProvider, (prev, next) {
      final total = (next.apiTotalCost?['totalCost'] as num?)?.toDouble();
      if (total != null && total != prev?.apiTotalCost?['totalCost']) {
        ref.read(basketProvider.notifier).setApiTotalCost(total);
      }
    });
    final itemsCount = basketState.shoppingList.items.length;
    final apiTotal = (compState.apiTotalCost?['totalCost'] as num?)?.toDouble();
    final totalCost = apiTotal ?? basketState.shoppingList.getTotalCost();
    final stores = _filteredStores(compState.results);
    final selected = compState.selectedStore;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total estimado', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                      Text('S/ ${totalCost.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    ],
                  ),
                  Text('$itemsCount productos', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                  IconButton(
                    icon: Icon(_multiSelectMode ? Icons.checklist : Icons.checklist_outlined),
                    tooltip: 'Multi-parada',
                    onPressed: () => setState(() => _multiSelectMode = !_multiSelectMode),
                  ),
                ],
              ),
            ),
            if (compState.stockIssues.isNotEmpty)
              Container(
                width: double.infinity,
                color: Colors.orange.shade100,
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Stock: ${compState.stockIssues.join(', ')}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            SizedBox(
              height: 250,
              width: double.infinity,
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(-12.04318, -77.02824),
                  zoom: 12,
                ),
                markers: stores.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final store = entry.value;
                  final coords = resolveStoreCoordinates(store, idx, compState);
                  final isSelected = selected != null && selected['storeId'] == store['storeId'];

                  return Marker(
                    markerId: MarkerId(store['storeId'].toString()),
                    position: LatLng(coords['lat']!, coords['lng']!),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      isSelected ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
                    ),
                    infoWindow: InfoWindow(
                      title: store['storeName'] as String? ?? 'Desconocida',
                      snippet: 'S/ ${((store['totalCost'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                    ),
                    onTap: () => ref.read(comparisonProvider.notifier).selectStore(store),
                  );
                }).toSet(),
              ),
            ),
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Todas'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Supermercados'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Conveniencia'),
                    const SizedBox(width: 8),
                    _buildFilterChip('24h'),
                  ],
                ),
              ),
            ),
            if (selected != null)
              Container(
                width: double.infinity,
                color: SmartCartTheme.primaryColor.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Destino: ${selected['storeName']} — Toca "Ir a tienda" para navegar',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (compState.trustProfile != null)
                      Text(
                        'Confianza: ${compState.trustProfile!['trustScore'] ?? compState.trustProfile!['score'] ?? compState.trustProfile!['accuracyPercentage'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12, color: Colors.teal),
                      ),
                    if (selected['storeId'] != null)
                      Builder(builder: (context) {
                        final ratings = compState.storeRatings[(selected['storeId'] as num).toInt()];
                        if (ratings == null) return const SizedBox.shrink();
                        return Text(
                          '★ ${ratings['averageRating'] ?? ratings['currentAverage'] ?? 'N/A'} (${ratings['totalVotes'] ?? ''} votos)',
                          style: const TextStyle(fontSize: 12, color: Colors.amber),
                        );
                      }),
                  ],
                ),
              ),
            Expanded(
              child: compState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : compState.error != null
                      ? Center(child: Text('Error: ${compState.error}'))
                      : stores.isEmpty
                          ? const Center(child: Text('No hay resultados'))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: stores.length,
                              separatorBuilder: (c, i) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final store = stores[index];
                                final isBest = index == 0;
                                final isBad = (store['savingsPercent'] ?? 0) < 0;
                                final price = (store['totalCost'] as num?)?.toDouble() ?? 0.0;
                                final savings =
                                    store['savingsPercent'] != null ? '${store['savingsPercent']}%' : '0%';
                                final isSelected = selected != null && selected['storeId'] == store['storeId'];
                                final storeId = (store['storeId'] as num?)?.toInt();
                                final inMulti = storeId != null && compState.selectedStoreIds.contains(storeId);
                                final isFav = storeId != null && basketState.favoriteStores.any((s) => (s['storeId'] as num?)?.toInt() == storeId);
                                final coords = resolveStoreCoordinates(store, index, compState);
                                final userLat = _userLat ?? -12.04318;
                                final userLng = _userLng ?? -77.02824;
                                final distKm = _haversineKm(userLat, userLng, coords['lat']!, coords['lng']!);

                                return InkWell(
                                  onTap: () {
                                    if (_multiSelectMode) {
                                      ref.read(comparisonProvider.notifier).toggleStoreSelection(store);
                                    } else {
                                      ref.read(comparisonProvider.notifier).selectStore(store);
                                      if (storeId != null) {
                                        ref.read(basketProvider.notifier).setSelectedStoreId(storeId);
                                        ref.read(basketProvider.notifier).checkSubstitutesForStore(storeId);
                                        final listId = ref.read(basketProvider).remoteListId;
                                        if (listId != null) {
                                          ref.read(comparisonProvider.notifier).verifyStock(listId, storeId);
                                        }
                                      }
                                    }
                                  },
                                  onLongPress: () {
                                    setState(() => _multiSelectMode = true);
                                    ref.read(comparisonProvider.notifier).toggleStoreSelection(store);
                                  },
                                  child: Container(
                                    color: (isSelected || inMulti) ? SmartCartTheme.primaryColor.withOpacity(0.08) : null,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: isBest
                                                ? Colors.lightGreenAccent.shade700
                                                : Theme.of(context).colorScheme.surfaceVariant,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('${index + 1}',
                                              style: TextStyle(
                                                  fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          _multiSelectMode
                                              ? (inMulti ? Icons.check_box : Icons.check_box_outline_blank)
                                              : (isSelected ? Icons.radio_button_checked : Icons.radio_button_off),
                                          color: (isSelected || inMulti) ? SmartCartTheme.primaryColor : Colors.grey,
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey, size: 20),
                                          onPressed: storeId == null
                                              ? null
                                              : () => ref.read(basketProvider.notifier).toggleFavoriteStore({
                                                    'storeId': storeId,
                                                    'storeName': store['storeName'],
                                                  }),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(store['storeName'] as String? ?? 'Desconocida',
                                                  style: TextStyle(
                                                      fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                              Text('${distKm.toStringAsFixed(1)} km',
                                                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('S/ ${price.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                    fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                            Text(
                                              savings,
                                              style: TextStyle(
                                                color: isBest ? Colors.green : (isBad ? Colors.red : Colors.grey),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: compState.isLoading ? null : _startRouteToSelectedStore,
        backgroundColor: SmartCartTheme.primaryColor,
        icon: const Icon(Icons.directions, color: Colors.white),
        label: Text(
          _multiSelectMode && compState.selectedStoreIds.length > 1 ? 'Ruta multi-parada' : 'Ir a tienda',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final active = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = label);
        final listId = ref.read(basketProvider).remoteListId;
        if (listId != null) {
          ref.read(comparisonProvider.notifier).comparePrices(listId, storeFormat: _filterFormat(label));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? SmartCartTheme.primaryColor : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color)),
      ),
    );
  }
}
