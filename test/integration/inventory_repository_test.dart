import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inventario/core/database/app_database.dart';
import 'package:inventario/core/database/demo_seed.dart';
import 'package:inventario/core/errors/app_exception.dart';
import 'package:inventario/features/inventory/data/repositories/sqlite_inventory_repository.dart';
import 'package:inventario/features/inventory/domain/entities/movement.dart';
import 'package:inventario/features/inventory/domain/entities/movement_type.dart';
import 'package:inventario/features/inventory/domain/usecases/register_movement.dart';
import 'package:inventario/features/products/data/repositories/sqlite_product_repository.dart';
import 'package:inventario/features/products/domain/entities/product.dart';
import 'package:inventario/features/products/domain/usecases/product_usecases.dart';
import 'package:inventario/features/settings/data/repositories/sqlite_profile_repository.dart';
import 'package:inventario/features/settings/domain/entities/local_profile.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Pruebas de integracion sobre una base SQLite real (ffi). Verifican las
/// reglas de inventario y la atomicidad de cada operacion.
void main() {
  late Directory tempDir;
  late AppDatabase database;
  late SqliteProductRepository products;
  late SqliteInventoryRepository inventory;
  late SqliteProfileRepository profiles;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('inventario_test');
    database = AppDatabase(directoryResolver: () async => tempDir.path);
    await database.database;
    products = SqliteProductRepository(database);
    inventory = SqliteInventoryRepository(database);
    profiles = SqliteProfileRepository(database);
  });

  tearDown(() async {
    await database.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<Product> createProduct({int initialStock = 0, int minimum = 5}) async {
    return products.create(
      Product(
        code: 'TEST-001',
        name: 'Producto de prueba',
        purchasePrice: 10,
        salePrice: 15,
        minimumStock: minimum,
      ),
      initialStock: initialStock,
      responsible: 'Tester',
    );
  }

  group('Persistencia', () {
    test('el stock inicial se registra como movimiento de entrada', () async {
      final product = await createProduct(initialStock: 20);

      expect(product.currentStock, 20);

      final movements = await inventory.getMovementsForProduct(product.id!);
      expect(movements, hasLength(1));
      expect(movements.first.type, MovementType.entrada);
      expect(movements.first.quantity, 20);
      expect(movements.first.previousStock, 0);
      expect(movements.first.resultingStock, 20);
    });

    test('los datos sobreviven al cierre y reapertura de la base', () async {
      final product = await createProduct(initialStock: 12);
      await database.close();

      final reopened = SqliteProductRepository(database);
      final loaded = await reopened.getById(product.id!);

      expect(loaded, isNotNull);
      expect(loaded!.currentStock, 12);
      expect(loaded.code, 'TEST-001');
    });
  });

  group('Transaccionalidad', () {
    test('registra el movimiento y actualiza el stock en una sola operacion',
        () async {
      final product = await createProduct(initialStock: 20);

      final result = await inventory.registerMovement(
        productId: product.id!,
        type: MovementType.salida,
        quantity: 16,
        reason: 'Venta',
        responsible: 'Tester',
      );

      expect(result.movement.previousStock, 20);
      expect(result.movement.resultingStock, 4);
      expect(result.product.currentStock, 4);

      final reloaded = await products.getById(product.id!);
      expect(reloaded!.currentStock, 4);
    });

    test('una salida invalida no deja cambios en stock ni en movimientos',
        () async {
      final product = await createProduct(initialStock: 4);
      final before = await inventory.countMovementsForProduct(product.id!);

      await expectLater(
        inventory.registerMovement(
          productId: product.id!,
          type: MovementType.salida,
          quantity: 5,
          reason: 'Venta',
          responsible: 'Tester',
        ),
        throwsA(isA<InsufficientStockException>()),
      );

      final reloaded = await products.getById(product.id!);
      final after = await inventory.countMovementsForProduct(product.id!);

      expect(reloaded!.currentStock, 4);
      expect(after, before);
    });

    test('un motivo vacio no deja cambios en stock ni en movimientos',
        () async {
      final product = await createProduct(initialStock: 10);
      final before = await inventory.countMovementsForProduct(product.id!);

      await expectLater(
        inventory.registerMovement(
          productId: product.id!,
          type: MovementType.entrada,
          quantity: 5,
          reason: '   ',
          responsible: 'Tester',
        ),
        throwsA(isA<ValidationException>()),
      );

      final reloaded = await products.getById(product.id!);
      final after = await inventory.countMovementsForProduct(product.id!);

      expect(reloaded!.currentStock, 10);
      expect(after, before);
    });
  });

  group('Reglas de negocio', () {
    test('registra la cadena completa del flujo de aceptacion', () async {
      final product = await createProduct(initialStock: 0, minimum: 5);

      await inventory.registerMovement(
        productId: product.id!,
        type: MovementType.entrada,
        quantity: 20,
        reason: 'Compra a proveedor',
        responsible: 'Tester',
      );
      var current = await products.getById(product.id!);
      expect(current!.currentStock, 20);

      await inventory.registerMovement(
        productId: product.id!,
        type: MovementType.salida,
        quantity: 16,
        reason: 'Venta',
        responsible: 'Tester',
      );
      current = await products.getById(product.id!);
      expect(current!.currentStock, 4);
      expect(current.isBelowMinimum, isTrue);

      final lowStock = await products.getBelowMinimumStock();
      expect(lowStock.map((p) => p.id), contains(product.id));

      await expectLater(
        inventory.registerMovement(
          productId: product.id!,
          type: MovementType.salida,
          quantity: 5,
          reason: 'Venta',
          responsible: 'Tester',
        ),
        throwsA(isA<InsufficientStockException>()),
      );

      final adjusted = await inventory.registerMovement(
        productId: product.id!,
        type: MovementType.ajuste,
        quantity: 3,
        reason: 'Conteo fisico: se hallaron 3 unidades',
        responsible: 'Tester',
      );
      expect(adjusted.movement.previousStock, 4);
      expect(adjusted.product.currentStock, 3);
    });

    test('un ajuste sin justificacion es rechazado por el caso de uso',
        () async {
      final product = await createProduct(initialStock: 10);
      final usecase = RegisterMovement(inventory);

      await expectLater(
        usecase(
          product: product,
          type: MovementType.ajuste,
          quantity: 4,
          reason: '  ',
          responsible: 'Tester',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('no permite registrar movimientos sin responsable', () async {
      final product = await createProduct(initialStock: 10);
      final usecase = RegisterMovement(inventory);

      await expectLater(
        usecase(
          product: product,
          type: MovementType.entrada,
          quantity: 1,
          reason: 'Compra',
          responsible: '',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('un producto con movimientos no se elimina, solo se desactiva',
        () async {
      final product = await createProduct(initialStock: 5);

      await expectLater(
        products.deleteIfUnused(product.id!),
        throwsA(isA<ProductHasMovementsException>()),
      );

      await products.setActive(product.id!, false);
      final reloaded = await products.getById(product.id!);
      expect(reloaded!.active, isFalse);
      expect(reloaded.currentStock, 5);
    });

    test('un producto sin movimientos si se puede eliminar', () async {
      final product = await createProduct();

      await products.deleteIfUnused(product.id!);

      expect(await products.getById(product.id!), isNull);
    });
  });

  group('Codigos', () {
    test('detecta codigos duplicados', () async {
      await createProduct();

      final available = await products.isCodeAvailable('TEST-001');
      expect(available, isFalse);
    });

    test('el mismo codigo esta disponible al editar el propio producto',
        () async {
      final product = await createProduct();

      final available = await products.isCodeAvailable(
        'TEST-001',
        excludingProductId: product.id,
      );
      expect(available, isTrue);
    });

    test('el caso de uso de creacion rechaza un codigo repetido', () async {
      await createProduct();
      final usecase = CreateProduct(products);

      await expectLater(
        usecase(
          const Product(
            code: 'TEST-001',
            name: 'Otro',
            purchasePrice: 1,
            salePrice: 2,
            minimumStock: 1,
          ),
        ),
        throwsA(isA<DuplicateCodeException>()),
      );
    });
  });

  group('Historial y filtros', () {
    test('filtra movimientos por producto, tipo y rango de fechas', () async {
      final product = await createProduct(initialStock: 10);
      await inventory.registerMovement(
        productId: product.id!,
        type: MovementType.salida,
        quantity: 2,
        reason: 'Venta',
        responsible: 'Tester',
      );

      final byProduct = await inventory.getMovements(
        filter: MovementFilter(productId: product.id),
      );
      expect(byProduct, hasLength(2));

      final byType = await inventory.getMovements(
        filter: const MovementFilter(type: MovementType.salida),
      );
      expect(byType, hasLength(1));
      expect(byType.first.type, MovementType.salida);

      final today = DateTime.now();
      final byRange = await inventory.getMovements(
        filter: MovementFilter(from: today, to: today),
      );
      expect(byRange, hasLength(2));

      final past = DateTime.now().subtract(const Duration(days: 30));
      final empty = await inventory.getMovements(
        filter: MovementFilter(from: past, to: past),
      );
      expect(empty, isEmpty);
    });
  });

  group('Perfil local', () {
    test('guarda y recupera el responsable por defecto', () async {
      await profiles.save(
        const LocalProfile(responsibleName: 'Ana', storeName: 'Tienda 1'),
      );

      final loaded = await profiles.load();
      expect(loaded.responsibleName, 'Ana');
      expect(loaded.storeName, 'Tienda 1');
      expect(loaded.initialized, isTrue);
    });
  });

  group('Datos de demostracion', () {
    test('carga 3 categorias y al menos 15 productos', () async {
      final db = await database.database;
      await DemoSeed.apply(db);

      expect(await products.countAll(), greaterThanOrEqualTo(15));
      expect(await products.getCategories(), hasLength(3));

      final movements = await inventory.getRecentMovements(limit: 100);
      expect(movements.length, greaterThanOrEqualTo(15));
    });

    test('es idempotente: aplicar dos veces no duplica datos', () async {
      final db = await database.database;
      await DemoSeed.apply(db);
      final firstCount = await products.countAll();
      await DemoSeed.apply(db);

      expect(await products.countAll(), firstCount);
    });
  });
}
