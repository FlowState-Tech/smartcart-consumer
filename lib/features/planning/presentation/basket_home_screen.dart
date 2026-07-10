import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../application/basket_notifier.dart';
import '../application/basket_state.dart';
import '../../../core/theme/smartcart_theme.dart';
import 'widgets/product_search_modal.dart';

class BasketHomeScreen extends ConsumerWidget {
  final Function(int) onNavigate;
  const BasketHomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basketState = ref.watch(basketProvider);
    final totalCost = basketState.effectiveTotalCost;

    ref.listen<BasketState>(basketProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red),
        );
        ref.read(basketProvider.notifier).clearMessages();
      }
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!), backgroundColor: Colors.green),
        );
        ref.read(basketProvider.notifier).clearMessages();
      }
      if (next.suggestedSubstitute != null && (prev == null || prev.suggestedSubstitute == null)) {
        final original = next.shoppingList.items.isNotEmpty ? next.shoppingList.items.last : null;
        if (original != null) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Ahorro detectado'),
              content: Text(
                '¿Cambiar ${original.name} por ${next.suggestedSubstitute!.brand} '
                'y ahorrar S/ ${(original.price - next.suggestedSubstitute!.price).toStringAsFixed(2)}?',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    ref.read(basketProvider.notifier).dismissSubstitute();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Mantener'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ref.read(basketProvider.notifier).acceptSubstitute(original, next.suggestedSubstitute!);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          );
        }
      }
    });

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
              icon: const Icon(Icons.list_alt, color: SmartCartTheme.primaryColor),
              tooltip: 'Mis listas',
              onPressed: () => _showListPicker(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.add_shopping_cart, color: SmartCartTheme.primaryColor),
              tooltip: 'Añadir producto',
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
              onPressed: () => _showBudgetDialog(context, ref, basketState),
              child: const Text('Presupuesto', style: TextStyle(color: SmartCartTheme.primaryColor)),
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
            if (basketState.isLoading) const LinearProgressIndicator(),
            if (basketState.isOverBudget)
              Container(
                width: double.infinity,
                color: Colors.red.withOpacity(0.1),
                padding: const EdgeInsets.all(8),
                child: Text(
                  '¡Presupuesto excedido! (S/ ${basketState.effectiveTotalCost.toStringAsFixed(2)} / S/ ${basketState.budget!.value.toStringAsFixed(2)})',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildList(context, basketState, ref),
                  _buildFavorites(context, basketState, ref),
                ],
              ),
            ),
            _buildBottomCard(context, ref, totalCost),
          ],
        ),
      ),
    );
  }

  void _showListPicker(BuildContext context, WidgetRef ref) async {
    final lists = await ref.read(basketProvider.notifier).fetchBuyerLists();
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Mis canastas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            if (lists.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No hay listas guardadas')),
            ...lists.map((list) {
              final id = (list['id'] as num?)?.toInt();
              return ListTile(
                title: Text(list['name']?.toString() ?? 'Canasta $id'),
                subtitle: Text('${(list['items'] as List?)?.length ?? '?'} items'),
                onTap: id == null
                    ? null
                    : () {
                        ref.read(basketProvider.notifier).switchToList(id);
                        Navigator.pop(ctx);
                      },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, WidgetRef ref, BasketState state) {
    final controller = TextEditingController(text: state.budget?.value.toStringAsFixed(0) ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Presupuesto máximo'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'S/ máximo', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null) ref.read(basketProvider.notifier).setBudget(amount);
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    final bytes = await ref.read(basketProvider.notifier).exportPdf();
    if (bytes == null || !context.mounted) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/canasta_smartcart.pdf');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Mi canasta SmartCart',
      ),
    );
  }

  Widget _buildFavorites(BuildContext context, BasketState state, WidgetRef ref) {
    if (state.favoriteProducts.isEmpty) {
      return const Center(child: Text('Marca productos con ♥ al buscarlos', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.favoriteProducts.length,
      itemBuilder: (ctx, i) {
        final item = state.favoriteProducts[i];
        return ListTile(
          leading: const Icon(Icons.favorite, color: Colors.red),
          title: Text(item['name']?.toString() ?? item['productName']?.toString() ?? 'Producto'),
          subtitle: Text('S/ ${((item['price'] as num?) ?? 0).toStringAsFixed(2)}'),
          trailing: IconButton(
            icon: const Icon(Icons.add_shopping_cart, color: SmartCartTheme.primaryColor),
            onPressed: () => ref.read(basketProvider.notifier).addFavoriteToBasket(item),
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, BasketState state, WidgetRef ref) {
    final items = state.shoppingList.items;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tu canasta está vacía.\nAñade productos con el ícono + arriba.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.read(basketProvider.notifier).applyFamilyBasket(),
              child: const Text('Usar canasta básica familiar'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(item.name),
            subtitle: Text('S/ ${item.price.toStringAsFixed(2)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => ref.read(basketProvider.notifier).updateProductQuantity(item.id, item.quantity.value.toInt() - 1),
                ),
                Text('${item.quantity.value.toInt()}'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => ref.read(basketProvider.notifier).updateProductQuantity(item.id, item.quantity.value.toInt() + 1),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => ref.read(basketProvider.notifier).removeProduct(item.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomCard(BuildContext context, WidgetRef ref, double totalCost) {
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
                Text('S/ ${totalCost.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => onNavigate(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: SmartCartTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Comparar precios', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref.read(basketProvider.notifier).repeatLastBasket(),
                    child: const Text('Repetir'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _exportPdf(context, ref),
                    child: const Text('Exportar PDF'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
