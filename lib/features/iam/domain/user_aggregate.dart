import 'package:equatable/equatable.dart';
import 'value_objects.dart';

class UserAggregate extends Equatable {
  final String id;
  final UserEmail email;
  final String token;

  const UserAggregate({
    required this.id,
    required this.email,
    required this.token,
  });

  @override
  List<Object?> get props => [id, email, token];
}
