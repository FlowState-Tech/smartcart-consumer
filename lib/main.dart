import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'interface/login_page.dart';

void main() {
  runApp(const SmartCartApp());
}

class SmartCartApp extends StatelessWidget {
  const SmartCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartCart Consumer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A89DC), // SmartCart Blue
          primary: const Color(0xFF4A89DC),
          secondary: const Color(0xFF53A6D8), // Light Blue
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}