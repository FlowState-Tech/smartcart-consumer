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
    "Mi Canasta",
    "Comparar",
    "Ruta",
    "Validar",
    "Perfil",
  ];

  // Datos mock para la canasta
  final List<Map<String, dynamic>> _cartItems = [
    {"name": "Leche Gloria Evaporada 400g", "price": 3.80, "qty": 2, "icon": Icons.local_drink},
    {"name": "Pan de Molde Blanco", "price": 7.50, "qty": 1, "icon": Icons.bakery_dining},
    {"name": "Huevos Pardos x15", "price": 9.20, "qty": 1, "icon": Icons.egg},
    {"name": "Aceite Vegetal 1L", "price": 8.50, "qty": 1, "icon": Icons.opacity},
  ];

  double get _totalPrice {
    double total = 0;
    for (var item in _cartItems) {
      total += (item["price"] as double) * (item["qty"] as int);
    }
    return total;
  }

  void _incrementQty(int index) {
    setState(() {
      _cartItems[index]["qty"]++;
    });
  }

  void _decrementQty(int index) {
    setState(() {
      if (_cartItems[index]["qty"] > 1) {
        _cartItems[index]["qty"]--;
      } else {
        _cartItems.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBarColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final unselectedColor = isDark ? Colors.grey[600] : Colors.grey[400];
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;

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
      body: _buildBody(isDark, cardColor, textColor),
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
            icon: Icon(Icons.shopping_basket_outlined), 
            activeIcon: Icon(Icons.shopping_basket), 
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

  Widget _buildBody(bool isDark, Color cardColor, Color textColor) {
    if (_currentIndex == 4) return const ProfilePage();
    if (_currentIndex == 0) return _buildHomeTab(isDark, cardColor, textColor);
    
    return Center(
      child: Text(
        "Vista de ${_titles[_currentIndex]} en construcción",
        style: GoogleFonts.inter(
          fontSize: 16,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildHomeTab(bool isDark, Color cardColor, Color textColor) {
    if (_cartItems.isEmpty) {
      return Center(
        child: Text(
          "Tu canasta está vacía",
          style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[500]),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _cartItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              return _buildCartItem(item, index, isDark, cardColor, textColor);
            },
          ),
        ),
        // Total Footer
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              )
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Estimado",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      "S/ ${_totalPrice.toStringAsFixed(2)}",
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF4A89DC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Generar Ruta de Compras",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index, bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Icon Placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item["icon"], color: Colors.grey[500], size: 30),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["name"],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  "S/ ${item["price"].toStringAsFixed(2)}",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A89DC),
                  ),
                ),
              ],
            ),
          ),
          // Quantity Selector
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  color: textColor,
                  onPressed: () => _decrementQty(index),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                Text(
                  "${item["qty"]}",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  color: textColor,
                  onPressed: () => _incrementQty(index),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
