import 'package:equatable/equatable.dart';

class WalletBalance extends Equatable {
  final int points;

  const WalletBalance(this.points);

  WalletBalance add(int amount) {
    if (amount < 0) throw ArgumentError('Amount must be positive');
    return WalletBalance(points + amount);
  }

  WalletBalance subtract(int amount) {
    if (amount < 0) throw ArgumentError('Amount must be positive');
    if (points - amount < 0) throw ArgumentError('Insufficient points');
    return WalletBalance(points - amount);
  }

  @override
  List<Object?> get props => [points];
}

class GamificationBadge extends Equatable {
  final String id;
  final String name;
  final String description;
  final String iconCode;

  const GamificationBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconCode,
  });

  @override
  List<Object?> get props => [id, name, description, iconCode];
}
