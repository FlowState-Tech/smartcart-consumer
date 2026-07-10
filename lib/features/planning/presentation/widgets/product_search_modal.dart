import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/providers/session_providers.dart';
import '../../../../core/theme/smartcart_theme.dart';
import '../../application/basket_notifier.dart';
import '../../domain/entities.dart';
import '../../domain/value_objects.dart';
import '../../infrastructure/product_catalog_service.dart';

class ProductSearchModal extends ConsumerStatefulWidget {
  const ProductSearchModal({super.key});

  @override
  ConsumerState<ProductSearchModal> createState() => _ProductSearchModalState();
}

class _ProductSearchModalState extends ConsumerState<ProductSearchModal> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  bool _showScanner = false;
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPopular());
  }

  Future<void> _loadPopular() async {
    setState(() => _isSearching = true);
    try {
      final catalog = sl<ProductCatalogService>();
      final buyerId = ref.read(optionalBuyerIdProvider);
      final results = await catalog.getPopularProducts(buyerId: buyerId);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudieron cargar productos: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      await _loadPopular();
      return;
    }

    setState(() => _isSearching = true);
    try {
      final catalog = sl<ProductCatalogService>();
      final buyerId = ref.read(optionalBuyerIdProvider);
      final results = await catalog.search(query.trim(), buyerId: buyerId);
      setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _addProduct(Map<String, dynamic> item) {
    ref.read(basketProvider.notifier).addProduct(
          ProductItem(
            id: item['sku'].toString(),
            name: item['name'].toString(),
            brand: item['brand']?.toString() ?? '',
            price: (item['price'] as num?)?.toDouble() ?? 0,
            quantity: Quantity(1, 'unit'),
            storeType: 'supermarket',
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_showScanner) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            AppBar(
              title: const Text('Escanear código'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _showScanner = false),
              ),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final code = capture.barcodes.firstOrNull?.rawValue;
                  if (code != null) {
                    setState(() => _showScanner = false);
                    _searchController.text = code;
                    _search(code);
                  }
                },
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
          ),
          Text('Buscar productos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Productos del catálogo del backend', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Nombre o código de barras',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onSubmitted: _search,
                  onChanged: (v) {
                    if (v.length >= 3) _search(v);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => setState(() => _showScanner = true),
                icon: const Icon(Icons.qr_code_scanner),
                style: IconButton.styleFrom(backgroundColor: SmartCartTheme.primaryColor, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isSearching) const LinearProgressIndicator(),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _isSearching ? 'Cargando productos...' : 'Sin resultados. Prueba "leche" o "GL-123"',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final item = _results[index];
                      final sku = item['sku'].toString();
                      final isFav = ref.watch(basketProvider.select((s) => s.favoriteProducts.any((p) => (p['sku'] ?? p['id']) == sku)));

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: SmartCartTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.shopping_bag, color: SmartCartTheme.primaryColor),
                        ),
                        title: Text(item['name'].toString()),
                        subtitle: Text('${item['brand']} · S/ ${((item['price'] as num?) ?? 0).toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : null),
                              onPressed: () => ref.read(basketProvider.notifier).toggleFavoriteProduct(item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: SmartCartTheme.primaryColor),
                              onPressed: () => _addProduct(item),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
