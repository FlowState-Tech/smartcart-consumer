import 'entities.dart';

class UnitMeasureComparisonService {
  // US24: Calculate exact value per kilogram or liter
  static ProductItem normalizePrice(ProductItem item) {
    if (item.quantity.unit == 'kg' || item.quantity.unit == 'L') {
      final normalizedPrice = item.price / item.quantity.value;
      return item.copyWith(normalizedUnitPrice: normalizedPrice);
    }
    // If it's just 'unit', normalized price is the same as price
    return item.copyWith(normalizedUnitPrice: item.price);
  }
}

class SubstituteProductPolicyService {
  // US33: Automatically process and return a reactive suggestion of the store's white-label equivalent
  static ProductItem? suggestSubstitute(ProductItem item) {
    final premiumBrands = ['Gloria', 'Alicorp', 'Nestle', 'Coca Cola'];
    
    if (premiumBrands.contains(item.brand)) {
      // White-label equivalent representing real net savings (> 15%)
      final whiteLabelPrice = item.price * 0.75; // 25% savings
      
      return ProductItem(
        id: '${item.id}_substitute',
        name: '${item.name} (Marca Blanca)',
        brand: 'Bell\'s / Tottus',
        price: whiteLabelPrice,
        quantity: item.quantity,
        storeType: item.storeType,
      );
    }
    
    return null;
  }
}
