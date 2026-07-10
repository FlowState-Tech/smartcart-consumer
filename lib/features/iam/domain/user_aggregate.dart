import 'package:equatable/equatable.dart';
import 'value_objects.dart';

class UserAggregate extends Equatable {
  final String id;
  final UserEmail email;
  final String token;
  final String? username;

  const UserAggregate({
    required this.id,
    required this.email,
    required this.token,
    this.username,
  });

  String get displayName {
    if (username != null && username!.isNotEmpty) return username!;
    final local = email.value.split('@').first;
    if (local.isEmpty) return 'Usuario';
    return local[0].toUpperCase() + local.substring(1);
  }

  @override
  List<Object?> get props => [id, email, username, token];
}
