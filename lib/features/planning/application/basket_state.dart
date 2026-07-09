import 'package:equatable/equatable.dart';
import '../domain/shopping_list.dart';
import '../domain/value_objects.dart';
import '../domain/entities.dart';

class BasketState extends Equatable {
  final ShoppingList shoppingList;
  final int? remoteListId;
  final Budget? budget;
  final ProductItem? suggestedSubstitute;

  const BasketState({
    required this.shoppingList,
    this.remoteListId,
    this.budget,
    this.suggestedSubstitute,
  });

  BasketState copyWith({
    ShoppingList? shoppingList,
    int? remoteListId,
    Budget? budget,
    ProductItem? suggestedSubstitute,
    bool clearSubstitute = false,
  }) {
    return BasketState(
      shoppingList: shoppingList ?? this.shoppingList,
      remoteListId: remoteListId ?? this.remoteListId,
      budget: budget ?? this.budget,
      suggestedSubstitute: clearSubstitute ? null : (suggestedSubstitute ?? this.suggestedSubstitute),
    );
  }

  bool get isOverBudget {
    if (budget == null) return false;
    return !shoppingList.isWithinBudget(budget!);
  }

  @override
  List<Object?> get props => [shoppingList, remoteListId, budget, suggestedSubstitute];
}
