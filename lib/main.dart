import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/smartcart_theme.dart';
import 'core/di/injection_container.dart' as di;
import 'core/presentation/auth_gate.dart';
import 'core/theme/theme_notifier.dart';
import 'core/network/session_events.dart';
import 'features/iam/application/auth_notifier.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  SessionEvents.onSessionExpired = () {
    di.sl<AuthNotifier>().forceLogout();
    scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Tu sesión expiró. Inicia sesión nuevamente.'),
        backgroundColor: Colors.orange,
      ),
    );
  };

  runApp(
    const ProviderScope(
      child: SmartCartApp(),
    ),
  );
}

class SmartCartApp extends ConsumerWidget {
  const SmartCartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'SmartCart',
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: SmartCartTheme.lightTheme,
      darkTheme: SmartCartTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}
