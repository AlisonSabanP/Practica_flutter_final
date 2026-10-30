import 'package:sqflite/sqflite.dart';

/// Datos de demostracion: 3 categorias y 16 productos con movimientos
/// iniciales coherentes. El stock inicial siempre se registra como un
/// movimiento de entrada, nunca como valor directo en la tabla.
abstract final class DemoSeed {
  static const String seedVersion = '1';

  static const List<String> categories = [
    'Abarrotes',
    'Bebidas',
    'Aseo',
  ];

  /// code, name, categoryIndex, purchase, sale, minimum, initialStock
  static const List<List<Object>> products = [
    ['ABR-001', 'Arroz blanco 1 kg', 0, 4.20, 5.90, 10, 40],
    ['ABR-002', 'Azucar refinada 1 kg', 0, 3.80, 5.20, 10, 35],
    ['ABR-003', 'Aceite de girasol 1 L', 0, 6.50, 8.90, 8, 24],
    ['ABR-004', 'Frijol negro 500 g', 0, 4.90, 6.80, 12, 30],
    ['ABR-005', 'Harina de trigo 1 kg', 0, 3.50, 4.90, 10, 18],
    ['ABR-006', 'Sal fina 500 g', 0, 1.10, 2.00, 15, 22],
    ['BEB-001', 'Agua purificada 600 ml', 1, 0.80, 1.50, 24, 96],
    ['BEB-002', 'Gaseosa cola 1.5 L', 1, 4.10, 6.50, 12, 30],
    ['BEB-003', 'Jugo de naranja 1 L', 1, 5.20, 7.80, 8, 12],
    ['BEB-004', 'Cafe molido 250 g', 1, 8.40, 11.90, 6, 9],
    ['BEB-005', 'Leche entera 1 L', 1, 4.60, 6.40, 12, 8],
    ['ASE-001', 'Jabon de bano 110 g', 2, 1.90, 3.20, 10, 25],
    ['ASE-002', 'Detergente en polvo 900 g', 2, 7.30, 10.50, 6, 7],
    ['ASE-003', 'Papel higienico x4', 2, 4.80, 7.20, 10, 14],
    ['ASE-004', 'Limpiador multiusos 500 ml', 2, 3.60, 5.40, 8, 6],
    ['ASE-005', 'Blanqueador 1 L', 2, 2.80, 4.30, 8, 4],
  ];

  /// Movimiento adicional de demostracion: code, type, quantity, reason, daysAgo
  static const List<List<Object>> extraMovements = [
    ['ABR-001', 'salida', 6, 'Venta mostrador', 3],
    ['BEB-001', 'salida', 12, 'Venta mostrador', 2],
    ['BEB-002', 'entrada', 6, 'Compra a proveedor', 2],
    ['ASE-002', 'salida', 1, 'Producto danado', 1],
    ['ABR-005', 'ajuste', 16, 'Conteo fisico mensual', 1],
  ];

  /// Indica si la base ya tiene los datos de demostracion cargados.
  static Future<bool> isSeeded(DatabaseExecutor db) async {
    final rows = await db.query(
      'profile',
      where: 'key = ?',
      whereArgs: ['demo_seed_version'],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return rows.first['value'] == seedVersion;
  }

  /// Carga los datos de demostracion dentro de una transaccion. Es idempotente:
  /// si la version ya esta aplicada no vuelve a insertar nada.
  static Future<void> apply(DatabaseExecutor db, {String responsible = 'Administrador'}) async {
    if (await isSeeded(db)) return;

    final categoryIds = <int>[];
    for (final name in categories) {
      final id = await db.insert(
        'categories',
        {'name': name},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      if (id != 0) {
        categoryIds.add(id);
      } else {
        final rows = await db.query('categories', where: 'name = ?', whereArgs: [name]);
        categoryIds.add(rows.first['id']! as int);
      }
    }

    final productIds = <String, int>{};
    final now = DateTime.now();
    for (final row in products) {
      final code = row[0] as String;
      final initialStock = row[6] as int;
      final productId = await db.insert('products', {
        'code': code,
        'name': row[1] as String,
        'description': '',
        'category_id': categoryIds[row[2] as int],
        'purchase_price': row[3] as double,
        'sale_price': row[4] as double,
        'current_stock': initialStock,
        'minimum_stock': row[5] as int,
        'active': 1,
      });
      productIds[code] = productId;

      await db.insert('movements', {
        'product_id': productId,
        'type': 'entrada',
        'quantity': initialStock,
        'previous_stock': 0,
        'resulting_stock': initialStock,
        'reason': 'Carga inicial de inventario',
        'responsible': responsible,
        'created_at': now
            .subtract(const Duration(days: 7))
            .millisecondsSinceEpoch,
      });
    }

    for (final row in extraMovements) {
      final code = row[0] as String;
      final productId = productIds[code]!;
      final type = row[1] as String;
      final quantity = row[2] as int;
      final daysAgo = row[4] as int;

      final current = await db.query(
        'products',
        columns: ['current_stock'],
        where: 'id = ?',
        whereArgs: [productId],
      );
      final previous = current.first['current_stock']! as int;
      final resulting = type == 'entrada'
          ? previous + quantity
          : type == 'salida'
              ? previous - quantity
              : quantity;

      await db.update(
        'products',
        {'current_stock': resulting},
        where: 'id = ?',
        whereArgs: [productId],
      );
      await db.insert('movements', {
        'product_id': productId,
        'type': type,
        'quantity': quantity,
        'previous_stock': previous,
        'resulting_stock': resulting,
        'reason': row[3] as String,
        'responsible': responsible,
        'created_at':
            now.subtract(Duration(days: daysAgo)).millisecondsSinceEpoch,
      });
    }

    await db.insert(
      'profile',
      {'key': 'demo_seed_version', 'value': seedVersion},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      'profile',
      {'key': 'responsible_name', 'value': responsible},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      'profile',
      {'key': 'store_name', 'value': 'Tienda principal'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> markSeeded(DatabaseExecutor db) async {
    await db.insert(
      'profile',
      {'key': 'demo_seed_version', 'value': seedVersion},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
