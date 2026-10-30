import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventario/app/home_screen.dart';
import 'package:inventario/app/shell_screen.dart';
import 'package:inventario/core/database/app_database.dart';
import 'package:inventario/core/database/demo_seed.dart';
import 'package:inventario/core/di/providers.dart';
import 'package:inventario/core/theme/app_theme.dart';
import 'package:inventario/features/products/data/repositories/sqlite_product_repository.dart';
import 'package:inventario/features/products/domain/entities/product.dart';
import 'package:inventario/features/products/presentation/screens/product_detail_screen.dart';
import 'package:inventario/features/products/presentation/screens/product_form_screen.dart';
import 'package:inventario/features/inventory/presentation/screens/movement_screen.dart';
import 'package:inventario/features/products/presentation/screens/products_screen.dart';
import 'package:inventario/features/reports/presentation/screens/reports_screen.dart';
import 'package:inventario/features/scanner/presentation/screens/scanner_screen.dart';
import 'package:inventario/features/settings/presentation/screens/profile_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Renderiza cada pantalla con datos de demostracion y guarda una captura PNG.
/// Se ejecuta con: flutter test --update-goldens test/golden
///
/// Este es el mecanismo de captura de pantallas del proyecto: el entorno de
/// compilacion no dispone de emulador con aceleracion, por lo que las capturas
/// se generan con el motor de render de Flutter.
/// El plugin de camara no tiene implementacion en el entorno de pruebas. Se
/// responde a sus canales para que la pantalla del escaner se pueda renderizar
/// sin dispositivo. La logica de lectura se verifica en las pruebas del
/// normalizador y en las pruebas de integracion.
void _stubScannerChannels() {
  const channel = MethodChannel(
    'dev.steenbakker.mobile_scanner/scanner/method',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'state':
          case 'request':
            return 1;
          default:
            return null;
        }
      });

  for (final name in const [
    'dev.steenbakker.mobile_scanner/scanner/event',
    'dev.steenbakker.mobile_scanner/scanner/deviceOrientation',
  ]) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          EventChannel(name),
          MockStreamHandler.inline(
            onListen: (arguments, sink) {},
            onCancel: (arguments) {},
          ),
        );
  }
}

void main() {
  late Directory tempDir;
  late AppDatabase database;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _stubScannerChannels();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('inventario_golden');
    database = AppDatabase(directoryResolver: () async => tempDir.path);
    final db = await database.database;
    await DemoSeed.apply(db, responsible: 'Administrador');
  });

  tearDown(() async {
    await database.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: child,
      ),
    );
  }

  Future<void> capture(
    WidgetTester tester,
    Widget screen,
    String name, {
    Duration settle = const Duration(milliseconds: 400),
  }) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(screen));
    // Las pantallas cargan datos de sqflite con E/S real. runAsync permite que
    // esas operaciones terminen antes de capturar el cuadro.
    await tester.runAsync(() async {
      await Future<void>.delayed(settle);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('screenshots/$name.png'),
    );
  }

  testWidgets('captura navegacion principal', (tester) async {
    await capture(tester, const ShellScreen(), '00_navegacion');
  });

  testWidgets('captura inicio', (tester) async {
    await capture(tester, const HomeScreen(), '01_inicio');
  });

  testWidgets('captura listado de productos', (tester) async {
    await capture(tester, const ProductsScreen(), '02_productos');
  });

  testWidgets('captura formulario de producto', (tester) async {
    await capture(tester, const ProductFormScreen(), '03_formulario_producto');
  });

  testWidgets('captura detalle de producto con etiquetas', (tester) async {
    final repository = SqliteProductRepository(database);
    late Product product;
    await tester.runAsync(() async {
      final found = await repository.getByCode('ABR-001');
      expect(found, isNotNull);
      product = found!;
    });
    await capture(
      tester,
      ProductDetailScreen(productId: product.id!),
      '04_detalle_producto',
    );
  });

  testWidgets('captura reportes e historial', (tester) async {
    await capture(tester, const ReportsScreen(), '05_reportes');
  });

  testWidgets('captura perfil local', (tester) async {
    await capture(tester, const ProfileScreen(), '06_perfil');
  });

  testWidgets('captura escaner', (tester) async {
    await capture(tester, const ScannerScreen(), '07_escaner');
  });

  testWidgets('captura movimiento de inventario', (tester) async {
    final repository = SqliteProductRepository(database);
    late Product product;
    await tester.runAsync(() async {
      final found = await repository.getByCode('ABR-001');
      product = found!;
    });
    await capture(tester, MovementScreen(product: product), '08_movimiento');
  });
}
