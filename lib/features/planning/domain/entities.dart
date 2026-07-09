import 'package:equatable/equatable.dart';
import 'value_objects.dart';

class ProductItem extends Equatable {
  final String id;
  final String name;
  final String brand;
  final double price;
  final Quantity quantity;
  final String storeType; // 'supermarket', 'convenience'
  
  // Computed property via domain service, optional here but useful for UI
  final double? normalizedUnitPrice; 

  const ProductItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.quantity,
    required this.storeType,
    this.normalizedUnitPrice,
  });

  ProductItem copyWith({
    String? id,
    String? name,
    String? brand,
    double? price,
    Quantity? quantity,
    String? storeType,
    double? normalizedUnitPrice,
  }) {
    return ProductItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      storeType: storeType ?? this.storeType,
      normalizedUnitPrice: normalizedUnitPrice ?? this.normalizedUnitPrice,
    );
  }

  @override
  List<Object?> get props => [id, name, brand, price, quantity, storeType, normalizedUnitPrice];
}

class PriceProjection extends Equatable {
  final double totalSupermarket;
  final double totalConvenience;

  const PriceProjection({
    required this.totalSupermarket,
    required this.totalConvenience,
  });

  @override
  List<Object?> get props => [totalSupermarket, totalConvenience];
}
