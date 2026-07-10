import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/iam/application/auth_notifier.dart';
import '../../features/iam/application/auth_state.dart';
import '../../features/iam/presentation/login_screen.dart';
import 'main_navigation_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is AuthInitial || authState is AuthLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authState is AuthAuthenticated) {
      return const MainNavigationScreen();
    }

    return const LoginScreen();
  }
}
