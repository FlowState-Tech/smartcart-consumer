import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/smartcart_theme.dart';
import '../../application/basket_notifier.dart';
import '../../domain/entities.dart';
import '../../domain/value_objects.dart';

class ProductSearchModal extends ConsumerStatefulWidget {
  const ProductSearchModal({super.key});

  @override
  ConsumerState<ProductSearchModal> createState() => _ProductSearchModalState();
}

class _ProductSearchModalState extends ConsumerState<ProductSearchModal> {
  String _searchQuery = '';

  final List<Map<String, dynamic>> _catalog = [
    {"sku": "GL-123", "name": "Leche Gloria", "brand": "Gloria", "price": 4.50},
    {"sku": "BI-456", "name": "Pan Bimbo", "brand": "Bimbo", "price": 8.00},
    {"sku": "AR-789", "name": "Arroz Costeño", "brand": "Costeño", "price": 4.20},
    {"sku": "HU-012", "name": "Huevos La Calera", "brand": "La Calera", "price": 7.50},
    {"sku": "AC-345", "name": "Aceite Primor", "brand": "Primor", "price": 9.50},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredCatalog = _catalog.where((item) {
      return item['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
             item['brand'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.7, // 70% of screen height
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Buscar Productos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Ej. Pan Bimbo, Leche...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          // Results List
          Expanded(
            child: filteredCatalog.isEmpty
                ? const Center(child: Text('No se encontraron productos'))
                : ListView.builder(
                    itemCount: filteredCatalog.length,
                    itemBuilder: (context, index) {
                      final item = filteredCatalog[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: SmartCartTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.shopping_bag, color: SmartCartTheme.primaryColor),
                        ),
                        title: Text(item['name'], style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                        subtitle: Text(item['brand'], style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle, color: SmartCartTheme.primaryColor),
                          onPressed: () {
                            ref.read(basketProvider.notifier).addProduct(
                              ProductItem(
                                id: item['sku'],
                                name: item['name'],
                                brand: item['brand'],
                                price: item['price'],
                                quantity: Quantity(1, 'unit'),
                                storeType: 'supermarket',
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("${item['name']} añadido a la canasta"), duration: const Duration(seconds: 1)),
                            );
                          },
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
