import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_page.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBarColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final unselectedColor = isDark ? Colors.grey[600] : Colors.grey[400];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _currentIndex == 4 ? null : AppBar(
        backgroundColor: navBarColor,
        elevation: 1,
        centerTitle: true,
        title: Text(
          _titles[_currentIndex],
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: _currentIndex == 4 
          ? const ProfilePage()
          : Center(
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
        unselectedItemColor: unselectedColor,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: navBarColor,
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
