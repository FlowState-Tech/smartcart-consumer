import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../planning/application/basket_notifier.dart';
import '../../../core/theme/smartcart_theme.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basketState = ref.watch(basketProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Productos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (basketState.favoriteProducts.isEmpty)
            const Text('Sin productos favoritos', style: TextStyle(color: Colors.grey))
          else
            ...basketState.favoriteProducts.map((p) {
              return ListTile(
                leading: const Icon(Icons.shopping_bag, color: SmartCartTheme.primaryColor),
                title: Text(p['name']?.toString() ?? p['productName']?.toString() ?? 'Producto'),
                subtitle: Text(p['brand']?.toString() ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: SmartCartTheme.primaryColor),
                  onPressed: () => ref.read(basketProvider.notifier).addFavoriteToBasket(p),
                ),
              );
            }),
          const SizedBox(height: 24),
          Text('Tiendas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (basketState.favoriteStores.isEmpty)
            const Text('Sin tiendas favoritas', style: TextStyle(color: Colors.grey))
          else
            ...basketState.favoriteStores.map((s) {
              return ListTile(
                leading: const Icon(Icons.store, color: SmartCartTheme.primaryColor),
                title: Text(s['storeName']?.toString() ?? 'Tienda'),
                subtitle: Text('ID: ${s['storeId']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  onPressed: () => ref.read(basketProvider.notifier).toggleFavoriteStore(s),
                ),
              );
            }),
        ],
      ),
    );
  }
}
