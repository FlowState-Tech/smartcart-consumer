import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/planning/presentation/basket_home_screen.dart';
import '../../features/planning/presentation/comparador_screen.dart';
import '../../features/journey/presentation/active_route_map_screen.dart';
import '../../features/experience/presentation/validation_screen.dart';
import '../../features/iam/presentation/profile_screen.dart';
import '../../../core/theme/smartcart_theme.dart';
import '../../features/planning/application/basket_notifier.dart';
import '../../features/planning/application/comparison_notifier.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    if (index == 1) {
      final remoteListId = ref.read(basketProvider).remoteListId;
      if (remoteListId != null) {
        ref.read(comparisonProvider.notifier).comparePrices(remoteListId);
      }
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          BasketHomeScreen(onNavigate: _switchTab),
          const ComparadorScreen(),
          const ActiveRouteMapScreen(),
          const ValidationScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _switchTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: SmartCartTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'Comparar'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), activeIcon: Icon(Icons.location_on), label: 'Ruta'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: 'Validar'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
