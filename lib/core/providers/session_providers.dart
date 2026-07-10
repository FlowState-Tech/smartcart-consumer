import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/iam/application/auth_notifier.dart';
import '../../features/iam/application/auth_state.dart';

int? resolveBuyerId(AuthState auth) {
  if (auth is! AuthAuthenticated) return null;
  return int.tryParse(auth.user.id);
}

/// Buyer id when authenticated; null otherwise (safe for catalog browsing).
final optionalBuyerIdProvider = Provider<int?>((ref) {
  return resolveBuyerId(ref.watch(authProvider));
});

/// Resolves the authenticated buyer id for API calls that require it.
final currentBuyerIdProvider = Provider<int>((ref) {
  final id = ref.watch(optionalBuyerIdProvider);
  if (id != null) return id;
  final auth = ref.watch(authProvider);
  if (auth is AuthAuthenticated) {
    throw StateError('ID de comprador inválido: ${auth.user.id}');
  }
  throw StateError('Sin sesión activa');
});

final currentBuyerIdStringProvider = Provider<String>((ref) {
  return ref.watch(currentBuyerIdProvider).toString();
});
