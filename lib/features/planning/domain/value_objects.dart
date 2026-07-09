import 'package:equatable/equatable.dart';

class Budget extends Equatable {
  final double value;

  Budget._(this.value);

  factory Budget(double input) {
    if (input < 0) {
      throw ArgumentError('Budget cannot be negative');
    }
    return Budget._(input);
  }

  @override
  List<Object?> get props => [value];
}

class Quantity extends Equatable {
  final double value;
  final String unit; // 'kg', 'L', 'unit'

  Quantity._(this.value, this.unit);

  factory Quantity(double value, String unit) {
    if (value <= 0) {
      throw ArgumentError('Quantity must be greater than zero');
    }
    return Quantity._(value, unit);
  }

  @override
  List<Object?> get props => [value, unit];
}
