import 'package:equatable/equatable.dart';

class UserEmail extends Equatable {
  final String value;

  UserEmail._(this.value);

  factory UserEmail(String input) {
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(input)) {
      throw ArgumentError('Invalid email format');
    }
    return UserEmail._(input);
  }

  @override
  List<Object?> get props => [value];
}

class UserPassword extends Equatable {
  final String _value; // Private to avoid plain-text exposure

  UserPassword._(this._value);

  factory UserPassword(String input) {
    if (input.length < 8) {
      throw ArgumentError('Password must be at least 8 characters long');
    }
    return UserPassword._(input);
  }

  String get value => _value; // To be used ONLY when encrypting or sending to API

  @override
  String toString() => 'UserPassword(******)';

  @override
  List<Object?> get props => [_value];
}
