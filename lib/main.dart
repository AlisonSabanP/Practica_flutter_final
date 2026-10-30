import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/database/demo_seed.dart';
import '../core/theme/app_theme.dart';
import 'app/shell_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _prepareDatabase();
  runApp(const ProviderScope(child: InventarioApp()));
}

/// Abre la base local y carga los datos de demostracion la primera vez que se
/// ejecuta la aplicacion.
Future<void> _prepareDatabase() async {
  final database = AppDatabase.instance;
  final db = await database.database;
  await DemoSeed.apply(db);
}

class InventarioApp extends StatelessWidget {
  const InventarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'INVENTARIO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const ShellScreen(),
    );
  }
}
