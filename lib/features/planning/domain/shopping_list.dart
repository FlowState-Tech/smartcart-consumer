import 'package:equatable/equatable.dart';
import 'entities.dart';
import 'value_objects.dart';

class ShoppingList extends Equatable {
  final String id;
  final List<ProductItem> items;

  const ShoppingList({
    required this.id,
    required this.items,
  });

  double getTotalCost() {
    return items.fold(0, (sum, item) => sum + (item.price * item.quantity.value));
  }

  bool isWithinBudget(Budget budget) {
    return getTotalCost() <= budget.value;
  }

  ShoppingList addItem(ProductItem item) {
    final existingIndex = items.indexWhere((i) => i.id == item.id);
    if (existingIndex >= 0) {
      final existingItem = items[existingIndex];
      final newQuantity = Quantity(existingItem.quantity.value + item.quantity.value, existingItem.quantity.unit);
      final updatedItem = existingItem.copyWith(quantity: newQuantity);
      final newItems = List<ProductItem>.from(items);
      newItems[existingIndex] = updatedItem;
      return ShoppingList(id: id, items: newItems);
    }
    return ShoppingList(id: id, items: List.from(items)..add(item));
  }

  ShoppingList updateItemQuantity(String productId, int newQuantityValue) {
    if (newQuantityValue <= 0) return removeItem(productId);
    
    final existingIndex = items.indexWhere((i) => i.id == productId);
    if (existingIndex >= 0) {
      final existingItem = items[existingIndex];
      final newQuantity = Quantity(newQuantityValue.toDouble(), existingItem.quantity.unit);
      final updatedItem = existingItem.copyWith(quantity: newQuantity);
      final newItems = List<ProductItem>.from(items);
      newItems[existingIndex] = updatedItem;
      return ShoppingList(id: id, items: newItems);
    }
    return this;
  }

  ShoppingList removeItem(String productId) {
    return ShoppingList(id: id, items: items.where((item) => item.id != productId).toList());
  }

  PriceProjection calculateProjection() {
    double superTotal = 0;
    double convTotal = 0;

    for (var item in items) {
      final itemTotal = item.price * item.quantity.value;
      if (item.storeType == 'supermarket') {
        superTotal += itemTotal;
        convTotal += itemTotal * 1.15; // Convenience is generally 15% more expensive
      } else {
        convTotal += itemTotal;
        superTotal += itemTotal * 0.85; 
      }
    }

    return PriceProjection(totalSupermarket: superTotal, totalConvenience: convTotal);
  }

  @override
  List<Object?> get props => [id, items];
}
