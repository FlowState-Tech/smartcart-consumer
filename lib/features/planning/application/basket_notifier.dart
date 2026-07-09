import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/shopping_list.dart';
import '../domain/value_objects.dart';
import '../domain/entities.dart';
import '../domain/domain_services.dart';
import 'basket_state.dart';

import '../../iam/application/auth_notifier.dart';
import '../../../core/di/injection_container.dart';
import '../infrastructure/shopping_list_remote_data_source.dart';

class BasketNotifier extends StateNotifier<BasketState> {
  final ShoppingListRemoteDataSource _dataSource;
  
  BasketNotifier(this._dataSource) : super(const BasketState(shoppingList: ShoppingList(id: 'default', items: [])));

  void setBudget(double amount) {
    try {
      final budget = Budget(amount);
      state = state.copyWith(budget: budget);
    } catch (_) {
      // Ignore invalid budget formats for now
    }
  }

  Future<void> addProduct(ProductItem rawItem) async {
    // US24: Normalize price immediately when adding
    final normalizedItem = UnitMeasureComparisonService.normalizePrice(rawItem);
    
    try {
      int listId;
      if (state.remoteListId != null) {
        listId = state.remoteListId!;
      } else {
        // Create a new list for this session
        final createRes = await _dataSource.createList(1, 'Mi Canasta ${DateTime.now().millisecondsSinceEpoch % 10000}');
        listId = createRes['id'] ?? createRes['listId'] ?? 1; // Fallback to 1 if not found
        state = state.copyWith(remoteListId: listId);
      }

      await _dataSource.addItem(listId, {
        'sku': normalizedItem.id,
        'productName': normalizedItem.name,
        'quantity': normalizedItem.quantity.value,
        'unit': normalizedItem.quantity.unit,
      });

      final updatedList = state.shoppingList.addItem(normalizedItem);
      
      // US33: Check for substitute
      final suggestion = SubstituteProductPolicyService.suggestSubstitute(normalizedItem);

      state = state.copyWith(
        shoppingList: updatedList,
        suggestedSubstitute: suggestion,
      );
    } catch (e) {
      // Revert or show error
      print('Error adding item: $e');
    }
  }

  Future<void> removeProduct(String productId) async {
    try {
      if (state.remoteListId != null) {
        // Assume itemId is passed as integer if numeric
        final itemId = int.tryParse(productId) ?? 1; // This is a limitation, but we try
        await _dataSource.removeItem(state.remoteListId!, itemId);
      }

      final updatedList = state.shoppingList.removeItem(productId);
      state = state.copyWith(shoppingList: updatedList);
    } catch (e) {
      print('Error removing item: $e');
    }
  }

  Future<void> updateProductQuantity(String productId, int newQuantity) async {
    // We update local state first for responsiveness
    final updatedList = state.shoppingList.updateItemQuantity(productId, newQuantity);
    state = state.copyWith(shoppingList: updatedList);
    // Ideally here we would also sync the new quantity with the remote data source
  }

  void acceptSubstitute(ProductItem originalItem, ProductItem substituteItem) {
    final listWithoutOriginal = state.shoppingList.removeItem(originalItem.id);
    final listWithSubstitute = listWithoutOriginal.addItem(substituteItem);
    
    state = state.copyWith(
      shoppingList: listWithSubstitute,
      clearSubstitute: true, // Dismiss suggestion
    );
  }

  void dismissSubstitute() {
    state = state.copyWith(clearSubstitute: true);
  }
}

// Global provider for the UI
final basketProvider = StateNotifierProvider<BasketNotifier, BasketState>((ref) {
  return BasketNotifier(sl<ShoppingListRemoteDataSource>());
});
