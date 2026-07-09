import 'package:equatable/equatable.dart';

class StoreReport extends Equatable {
  final String id;
  final String storeId;
  final String reason;
  final String imagePath;
  final DateTime reportedAt;

  const StoreReport({
    required this.id,
    required this.storeId,
    required this.reason,
    required this.imagePath,
    required this.reportedAt,
  });

  @override
  List<Object?> get props => [id, storeId, reason, imagePath, reportedAt];
}

class PriceVariation extends Equatable {
  final String productId;
  final double newPrice;

  const PriceVariation(this.productId, this.newPrice);

  @override
  List<Object?> get props => [productId, newPrice];
}

class OcrTicketResult extends Equatable {
  final String storeId;
  final List<PriceVariation> variations;
  final DateTime scannedAt;

  const OcrTicketResult({
    required this.storeId,
    required this.variations,
    required this.scannedAt,
  });

  @override
  List<Object?> get props => [storeId, variations, scannedAt];
}
