import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/smartcart_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/basket_notifier.dart';

import '../application/comparison_notifier.dart';

class ComparadorScreen extends ConsumerStatefulWidget {
  const ComparadorScreen({super.key});

  @override
  ConsumerState<ComparadorScreen> createState() => _ComparadorScreenState();
}

class _ComparadorScreenState extends ConsumerState<ComparadorScreen> {
  String _selectedFilter = 'Todas';

  @override
  Widget build(BuildContext context) {
    final basketState = ref.watch(basketProvider);
    final compState = ref.watch(comparisonProvider);
    final itemsCount = basketState.shoppingList.items.length;
    final totalCost = basketState.shoppingList.getTotalCost();
    
    // Apply local filtering based on storeName for demonstration
    var stores = compState.results;
    if (_selectedFilter == 'Supermercados') {
      stores = stores.where((s) => s['storeName'].toString().toLowerCase().contains('vea') || 
                                   s['storeName'].toString().toLowerCase().contains('metro') ||
                                   s['storeName'].toString().toLowerCase().contains('wong') ||
                                   s['storeName'].toString().toLowerCase().contains('tottus') ||
                                   s['storeName'].toString().toLowerCase().contains('super')).toList();
    } else if (_selectedFilter == 'Conveniencia') {
      stores = stores.where((s) => s['storeName'].toString().toLowerCase().contains('tambo') || 
                                   s['storeName'].toString().toLowerCase().contains('oxxo') ||
                                   s['storeName'].toString().toLowerCase().contains('mass')).toList();
    } else if (_selectedFilter == '24h') {
      stores = stores.where((s) => s['storeName'].toString().toLowerCase().contains('24h') ||
                                   s['storeName'].toString().toLowerCase().contains('listo')).toList();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                      Text('S/ ' + totalCost.toStringAsFixed(2), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    ],
                  ),
                  Text(itemsCount.toString() + ' productos', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                ],
              ),
            ),
            // Dynamic Google Map
            Container(
              height: 250,
              width: double.infinity,
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(-12.04318, -77.02824), // Center of Lima
                  zoom: 12,
                ),
                markers: stores.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var store = entry.value;
                  // Assign realistic mock coordinates based on store name
                  final name = (store['storeName'] as String? ?? '').toLowerCase();
                  double lat = -12.04318;
                  double lng = -77.02824;
                  if (name.contains('megaplaza')) { lat = -11.9934; lng = -77.0624; } // Independencia
                  else if (name.contains('encalada')) { lat = -12.1118; lng = -76.9723; } // Surco
                  else if (name.contains('san juan')) { lat = -11.9833; lng = -76.9983; } // SJL
                  else if (name.contains('listo')) { lat = -12.0921; lng = -77.0034; } // San Borja
                  else if (name.contains('tambos sur') || name.contains('lima sur')) { lat = -12.1512 + (idx * 0.001); lng = -76.9821; } // Sur
                  else if (name.contains('vea')) { lat = -12.0833; lng = -77.0500; } // San Isidro
                  else { lat = -12.04318 + (idx * 0.005); lng = -77.02824 - (idx * 0.005); } // Default spread
                  
                  return Marker(
                    markerId: MarkerId(store['storeId'].toString()),
                    position: LatLng(lat, lng),
                    infoWindow: InfoWindow(
                      title: store['storeName'] as String? ?? 'Desconocida',
                      snippet: 'S/ ${((store['totalCost'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                    ),
                  );
                }).toSet(),
              ),
            ),
            // Filters
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
            // Divider with slider mockup
            Container(
              height: 24,
              color: Colors.black87,
              child: Row(
                children: [
                  const Icon(Icons.arrow_left, color: Colors.white, size: 20),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_right, color: Colors.white, size: 20),
                ],
              ),
            ),
            // List
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
                          final isBest = index == 0; // The first result is assumed best if sorted
                          final isBad = (store['savingsPercent'] ?? 0) < 0;
                          final price = (store['totalCost'] as num?)?.toDouble() ?? 0.0;
                          final savings = store['savingsPercent'] != null ? '${store['savingsPercent']}%' : '0%';
                          final dist = '1.0 km'; // Mock distance since it's not in the API currently
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isBest ? Colors.lightGreenAccent.shade700 : Theme.of(context).colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('${index + 1}', style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(store['storeName'] as String? ?? 'Desconocida', style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                      Text(dist, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('S/ ' + price.toStringAsFixed(2), style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                    Text(
                                      savings, 
                                      style: TextStyle(color: isBest ? Colors.green : (isBad ? Colors.red : Colors.grey), fontWeight: FontWeight.bold)
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: SmartCartTheme.primaryColor,
        child: const Icon(Icons.location_on, color: Colors.white),
      ),
    );
  }

  Widget _buildPin(String num, Color color) {
    return Container(
      width: 36, height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0,2))]
      ),
      child: Text(num, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFilterChip(String label) {
    final active = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
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
