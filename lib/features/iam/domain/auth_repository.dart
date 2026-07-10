import 'user_aggregate.dart';
import 'value_objects.dart';

abstract class AuthRepository {
  Future<UserAggregate> signIn(String identifier, UserPassword password);
  Future<UserAggregate> signUp(UserEmail email, UserPassword password, {String? username});
  Future<void> logout();
  Future<void> deleteAccount();
  Future<UserAggregate?> checkSession();
}
