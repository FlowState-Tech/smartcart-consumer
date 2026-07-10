import 'package:equatable/equatable.dart';
import '../domain/shopping_list.dart';
import '../domain/value_objects.dart';
import '../domain/entities.dart';

class BasketState extends Equatable {
  final ShoppingList shoppingList;
  final int? remoteListId;
  final Budget? budget;
  final double? apiTotalCost;
  final int? selectedStoreId;
  final ProductItem? suggestedSubstitute;
  final String? errorMessage;
  final String? successMessage;
  final bool isLoading;
  final List<Map<String, dynamic>> favoriteProducts;
  final List<Map<String, dynamic>> favoriteStores;
  final List<Map<String, dynamic>> buyerLists;

  const BasketState({
    required this.shoppingList,
    this.remoteListId,
    this.budget,
    this.apiTotalCost,
    this.selectedStoreId,
    this.suggestedSubstitute,
    this.errorMessage,
    this.successMessage,
    this.isLoading = false,
    this.favoriteProducts = const [],
    this.favoriteStores = const [],
    this.buyerLists = const [],
  });

  double get effectiveTotalCost => apiTotalCost ?? shoppingList.getTotalCost();

  BasketState copyWith({
    ShoppingList? shoppingList,
    int? remoteListId,
    Budget? budget,
    double? apiTotalCost,
    int? selectedStoreId,
    ProductItem? suggestedSubstitute,
    String? errorMessage,
    String? successMessage,
    bool? isLoading,
    List<Map<String, dynamic>>? favoriteProducts,
    List<Map<String, dynamic>>? favoriteStores,
    List<Map<String, dynamic>>? buyerLists,
    bool clearSubstitute = false,
    bool clearMessages = false,
    bool clearApiTotal = false,
    bool clearSelectedStore = false,
  }) {
    return BasketState(
      shoppingList: shoppingList ?? this.shoppingList,
      remoteListId: remoteListId ?? this.remoteListId,
      budget: budget ?? this.budget,
      apiTotalCost: clearApiTotal ? null : (apiTotalCost ?? this.apiTotalCost),
      selectedStoreId: clearSelectedStore ? null : (selectedStoreId ?? this.selectedStoreId),
      suggestedSubstitute: clearSubstitute ? null : (suggestedSubstitute ?? this.suggestedSubstitute),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      isLoading: isLoading ?? this.isLoading,
      favoriteProducts: favoriteProducts ?? this.favoriteProducts,
      favoriteStores: favoriteStores ?? this.favoriteStores,
      buyerLists: buyerLists ?? this.buyerLists,
    );
  }

  bool get isOverBudget {
    if (budget == null) return false;
    return effectiveTotalCost > budget!.value;
  }

  @override
  List<Object?> get props => [
        shoppingList,
        remoteListId,
        budget,
        apiTotalCost,
        selectedStoreId,
        suggestedSubstitute,
        errorMessage,
        successMessage,
        isLoading,
        favoriteProducts,
        favoriteStores,
        buyerLists,
      ];
}
