import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/smartcart_theme.dart';
import '../application/basket_notifier.dart';
import '../application/basket_state.dart';
import '../domain/entities.dart';
import '../domain/value_objects.dart';

class BasketComparisonScreen extends ConsumerStatefulWidget {
  const BasketComparisonScreen({super.key});

  @override
  ConsumerState<BasketComparisonScreen> createState() => _BasketComparisonScreenState();
}

class _BasketComparisonScreenState extends ConsumerState<BasketComparisonScreen> {
  final _budgetController = TextEditingController();

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _addMockProduct() {
    // Helper to add a premium product to trigger the substitution policy
    final premiumItem = ProductItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Leche Evaporada',
      brand: 'Gloria',
      price: 4.50,
      quantity: Quantity(0.4, 'L'), // 400ml
      storeType: 'supermarket',
    );
    ref.read(basketProvider.notifier).addProduct(premiumItem);
  }

  @override
  Widget build(BuildContext context) {
    final basketState = ref.watch(basketProvider);
    final isOverBudget = basketState.isOverBudget;
    final totalCost = basketState.shoppingList.getTotalCost();
    final projection = basketState.shoppingList.calculateProjection();

    // Listen for substitution suggestions
    ref.listen<BasketState>(basketProvider, (BasketState? previous, BasketState next) {
      if (next.suggestedSubstitute != null && 
          (previous == null || previous.suggestedSubstitute == null)) {
        
        // Find the original item that triggered this (assuming it's the last added premium brand for this mock)
        final originalItem = next.shoppingList.items.last;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¡Ahorro Detectado!'),
            content: Text(
              'Has agregado ${originalItem.name} de ${originalItem.brand} por S/${originalItem.price.toStringAsFixed(2)}.\n\n'
              '¿Deseas cambiarlo por ${next.suggestedSubstitute!.brand} a S/${next.suggestedSubstitute!.price.toStringAsFixed(2)} y ahorrar dinero?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  ref.read(basketProvider.notifier).dismissSubstitute();
                  Navigator.of(ctx).pop();
                },
                child: const Text('Mantener Original'),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(basketProvider.notifier).acceptSubstitute(originalItem, next.suggestedSubstitute!);
                  Navigator.of(ctx).pop();
                },
                child: const Text('Aceptar Sustituto'),
              ),
            ],
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Armado de Canasta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: _addMockProduct,
            tooltip: 'Agregar producto de prueba',
          )
        ],
      ),
      body: Column(
        children: [
          // Budget Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _budgetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Presupuesto Máximo (S/)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.account_balance_wallet),
                errorText: isOverBudget ? '¡Presupuesto excedido!' : null,
              ),
              onChanged: (val) {
                final amount = double.tryParse(val) ?? 0.0;
                ref.read(basketProvider.notifier).setBudget(amount);
              },
            ),
          ),
          
          // Item List
          Expanded(
            child: ListView.builder(
              itemCount: basketState.shoppingList.items.length,
              itemBuilder: (context, index) {
                final item = basketState.shoppingList.items[index];
                return ListTile(
                  title: Text('${item.name} (${item.brand})'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Precio: S/${item.price.toStringAsFixed(2)}'),
                      // Highlight normalized price (US24)
                      if (item.normalizedUnitPrice != null)
                        Text(
                          'S/${item.normalizedUnitPrice!.toStringAsFixed(2)} por ${item.quantity.unit}',
                          style: TextStyle(
                            color: SmartCartTheme.secondaryColor, // Verde Menta
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => ref.read(basketProvider.notifier).removeProduct(item.id),
                  ),
                );
              },
            ),
          ),

          // Sliding Comparison Card
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: isOverBudget ? Colors.red.withAlpha(25) : Theme.of(context).cardColor,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Comparación de Formatos',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCostColumn('Supermercado', projection.totalSupermarket, SmartCartTheme.primaryColor),
                    _buildCostColumn('Conveniencia', projection.totalConvenience, Colors.orange),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Actual:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      'S/${totalCost.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isOverBudget ? Colors.red : SmartCartTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                if (isOverBudget)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'ALERTA: El costo total ha superado tu presupuesto.',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostColumn(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          'S/${amount.toStringAsFixed(2)}',
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
