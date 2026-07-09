import 'user_aggregate.dart';
import 'value_objects.dart';

abstract class AuthRepository {
  Future<UserAggregate> signIn(UserEmail email, UserPassword password);
  Future<UserAggregate> signUp(UserEmail email, UserPassword password);
  Future<void> logout();
  Future<void> deleteAccount(String token);
  Future<UserAggregate?> checkSession();
}
