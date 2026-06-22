import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Lista de títulos correspondientes a cada tab
  final List<String> _titles = [
    "Home",
    "Comparar",
    "Ruta",
    "Validar",
    "Perfil",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Text(
          _titles[_currentIndex],
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Center(
        child: Text(
          "Vista de ${_titles[_currentIndex]} en construcción",
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.grey[500],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF4A89DC),
        unselectedItemColor: Colors.grey[400],
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), 
            activeIcon: Icon(Icons.home), 
            label: "Home"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search), 
            label: "Comparar"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined), 
            activeIcon: Icon(Icons.location_on),
            label: "Ruta"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline), 
            activeIcon: Icon(Icons.check_circle),
            label: "Validar"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), 
            activeIcon: Icon(Icons.person),
            label: "Perfil"
          ),
        ],
      ),
    );
  }
}
