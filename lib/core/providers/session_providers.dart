import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/iam/application/auth_notifier.dart';
import '../../features/iam/application/auth_state.dart';

/// Resolves the authenticated buyer id for API calls.
final currentBuyerIdProvider = Provider<int>((ref) {
  final auth = ref.watch(authProvider);
  if (auth is AuthAuthenticated) {
    final id = int.tryParse(auth.user.id);
    if (id != null) return id;
    throw StateError('ID de comprador inválido: ${auth.user.id}');
  }
  throw StateError('Sin sesión activa');
});

final currentBuyerIdStringProvider = Provider<String>((ref) {
  return ref.watch(currentBuyerIdProvider).toString();
});
