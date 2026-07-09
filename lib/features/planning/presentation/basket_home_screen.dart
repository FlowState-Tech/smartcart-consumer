import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/basket_notifier.dart';
import '../application/basket_notifier.dart';
import '../application/basket_state.dart';
import '../domain/entities.dart';
import '../domain/value_objects.dart';
import '../../../core/theme/smartcart_theme.dart';
import 'widgets/product_search_modal.dart';

class BasketHomeScreen extends ConsumerWidget {
  final Function(int) onNavigate;
  const BasketHomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basketState = ref.watch(basketProvider);
    final totalCost = basketState.shoppingList.getTotalCost();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          title: Text('Mi Canasta', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_shopping_cart, color: SmartCartTheme.primaryColor),
              tooltip: 'Añadir producto de prueba',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const ProductSearchModal(),
                );
              },
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Editar', style: TextStyle(color: SmartCartTheme.primaryColor)),
            ),
          ],
          bottom: TabBar(
            labelColor: SmartCartTheme.primaryColor,
            unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
            indicatorColor: SmartCartTheme.primaryColor,
            tabs: const [
              Tab(text: 'Mi canasta'),
              Tab(text: 'Favoritas'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _buildList(context, basketState, ref),
                  const Center(child: Text('Favoritas', style: TextStyle(color: Colors.grey))),
                ],
              ),
            ),
            _buildBottomCard(context, totalCost),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, BasketState state, WidgetRef ref) {
    final items = state.shoppingList.items;

    if (items.isEmpty) {
      return const Center(
        child: Text('Tu canasta está vacía.\nAñade productos con el ícono + arriba.', 
          textAlign: TextAlign.center, 
          style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        return Card(
          color: Theme.of(ctx).colorScheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: TextStyle(fontSize: 16, color: Theme.of(ctx).textTheme.bodyLarge?.color)),
                      const SizedBox(height: 4),
                      Text('S/ ' + item.price.toStringAsFixed(2), style: const TextStyle(color: SmartCartTheme.primaryColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              ref.read(basketProvider.notifier).updateProductQuantity(item.id, item.quantity.value.toInt() - 1);
                            },
                            child: Text('-', style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color, fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                          Text(item.quantity.value.toInt().toString(), style: TextStyle(color: Theme.of(ctx).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              ref.read(basketProvider.notifier).updateProductQuantity(item.id, item.quantity.value.toInt() + 1);
                            },
                            child: Text('+', style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color, fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: () {
                        ref.read(basketProvider.notifier).removeProduct(item.id);
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomCard(BuildContext context, double totalCost) { 

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total estimado', style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color)),
                Text('S/ ' + totalCost.toStringAsFixed(2), style: TextStyle(fontSize: 24, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => onNavigate(1), 
              style: ElevatedButton.styleFrom(
                backgroundColor: SmartCartTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Comparar precios', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Repetir', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Exportar PDF', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
