import 'package:flutter/material.dart';

import '../features/products/presentation/screens/products_screen.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/scanner/presentation/screens/scanner_screen.dart';
import '../features/settings/presentation/screens/profile_screen.dart';
import 'home_screen.dart';

/// Contenedor principal con la navegacion inferior entre las cinco areas.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  /// Las paginas se crean solo cuando se visitan por primera vez. Evita iniciar
  /// la camara del escaner antes de que el usuario abra esa pestana.
  final Set<int> _visited = {0};

  static const List<Widget> _pages = [
    HomeScreen(),
    ProductsScreen(),
    ScannerScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Inicio',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: 'Productos',
    ),
    NavigationDestination(
      icon: Icon(Icons.qr_code_scanner),
      selectedIcon: Icon(Icons.qr_code_scanner),
      label: 'Escaner',
    ),
    NavigationDestination(
      icon: Icon(Icons.assessment_outlined),
      selectedIcon: Icon(Icons.assessment),
      label: 'Reportes',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < _pages.length; i++)
            _visited.contains(i) ? _pages[i] : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: _destinations,
        onDestinationSelected: (value) => setState(() {
          _index = value;
          _visited.add(value);
        }),
      ),
    );
  }
}
