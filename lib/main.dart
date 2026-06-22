import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'interface/login_page.dart';

// Notificador global para controlar el tema desde cualquier parte
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const SmartCartApp());
}

class SmartCartApp extends StatelessWidget {
  const SmartCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'SmartCart Consumer',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.light,
              seedColor: const Color(0xFF4A89DC),
              primary: const Color(0xFF4A89DC),
              secondary: const Color(0xFF53A6D8),
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
            useMaterial3: true,
          ),
            darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: const Color(0xFF4A89DC),
              primary: const Color(0xFF4A89DC),
              secondary: const Color(0xFF53A6D8),
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF1C1C1C),
          ),
          home: const LoginPage(),
        );
      },
    );
  }
}