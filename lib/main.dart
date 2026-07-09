import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/smartcart_theme.dart';
import 'core/di/injection_container.dart' as di;
import 'features/iam/presentation/login_screen.dart';
import 'core/theme/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init(); // Initialize Dependency Injection
  
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
      theme: SmartCartTheme.lightTheme,
      darkTheme: SmartCartTheme.darkTheme,
      themeMode: themeMode,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}