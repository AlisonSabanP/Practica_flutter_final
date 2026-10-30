import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_mapper.dart';

/// Implementacion sqflite del repositorio de productos.
class SqliteProductRepository implements ProductRepository {
  SqliteProductRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<Product>> getAll({bool includeInactive = true}) async {
    final db = await _appDatabase.database;
    final rows = await db.rawQuery(
      '${ProductMapper.selectWithCategory}'
      '${includeInactive ? '' : 'WHERE p.active = 1 '}'
      'ORDER BY p.name COLLATE NOCASE',
    );
    return rows.map(ProductMapper.fromRow).toList();
  }

  @override
  Future<List<Product>> search(String term, {bool includeInactive = false}) async {
    final value = term.trim();
    if (value.isEmpty) return getAll(includeInactive: includeInactive);
    final db = await _appDatabase.database;
    final rows = await db.rawQuery(
      '${ProductMapper.selectWithCategory}'
      'WHERE (p.code LIKE ? OR p.name LIKE ? OR IFNULL(c.name, \'\') LIKE ?) '
      '${includeInactive ? '' : 'AND p.active = 1 '}'
      'ORDER BY p.name COLLATE NOCASE',
      ['%$value%', '%$value%', '%$value%'],
    );
    return rows.map(ProductMapper.fromRow).toList();
  }

  @override
  Future<Product?> getById(int id) async {
    final db = await _appDatabase.database;
    final rows = await db.rawQuery(
      '${ProductMapper.selectWithCategory}WHERE p.id = ? LIMIT 1',
      [id],
    );
    if (rows.isEmpty) return null;
    return ProductMapper.fromRow(rows.first);
  }

  @override
  Future<Product?> getByCode(String code) async {
    final db = await _appDatabase.database;
    final rows = await db.rawQuery(
      '${ProductMapper.selectWithCategory}WHERE p.code = ? COLLATE NOCASE LIMIT 1',
      [code.trim()],
    );
    if (rows.isEmpty) return null;
    return ProductMapper.fromRow(rows.first);
  }

  @override
  Future<List<Product>> getBelowMinimumStock() async {
    final db = await _appDatabase.database;
    final rows = await db.rawQuery(
      '${ProductMapper.selectWithCategory}'
      'WHERE p.current_stock <= p.minimum_stock AND p.active = 1 '
      'ORDER BY p.current_stock ASC, p.name COLLATE NOCASE',
    );
    return rows.map(ProductMapper.fromRow).toList();
  }

  @override
  Future<List<Category>> getCategories() async {
    final db = await _appDatabase.database;
    final rows = await db.query('categories', orderBy: 'name COLLATE NOCASE');
    return rows.map(ProductMapper.categoryFromRow).toList();
  }

  @override
  Future<bool> isCodeAvailable(String code, {int? excludingProductId}) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'products',
      columns: ['id'],
      where: excludingProductId == null
          ? 'code = ? COLLATE NOCASE'
          : 'code = ? COLLATE NOCASE AND id <> ?',
      whereArgs: excludingProductId == null
          ? [code.trim()]
          : [code.trim(), excludingProductId],
      limit: 1,
    );
    return rows.isEmpty;
  }

  @override
  Future<int> countAll() async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM products');
    return (result.first['total'] as num).toInt();
  }

  @override
  Future<int> countBelowMinimumStock() async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM products '
      'WHERE current_stock <= minimum_stock AND active = 1',
    );
    return (result.first['total'] as num).toInt();
  }

  @override
  Future<double> inventoryValue() async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery(
      'SELECT IFNULL(SUM(current_stock * purchase_price), 0) AS total FROM products',
    );
    return (result.first['total'] as num).toDouble();
  }

  @override
  Future<Product> create(
    Product product, {
    int initialStock = 0,
    String responsible = '',
  }) async {
    final db = await _appDatabase.database;
    final id = await db.transaction<int>((txn) async {
      final productId = await txn.insert(
        'products',
        ProductMapper.toInsertRow(product),
      );
      if (initialStock > 0) {
        await txn.insert('movements', {
          'product_id': productId,
          'type': 'entrada',
          'quantity': initialStock,
          'previous_stock': 0,
          'resulting_stock': initialStock,
          'reason': 'Carga inicial de inventario',
          'responsible': responsible,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
        await txn.update(
          'products',
          {'current_stock': initialStock},
          where: 'id = ?',
          whereArgs: [productId],
        );
      }
      return productId;
    });
    final created = await getById(id);
    if (created == null) {
      throw const StorageException('No se pudo leer el producto recien creado.');
    }
    return created;
  }

  @override
  Future<Product> update(Product product) async {
    final id = product.id;
    if (id == null) {
      throw const ValidationException('El producto no tiene identificador.');
    }
    final db = await _appDatabase.database;
    // El stock nunca se edita desde el formulario: solo cambia por movimientos.
    final row = ProductMapper.toRow(product)..remove('current_stock');
    final updated = await db.update(
      'products',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (updated == 0) {
      throw const NotFoundException('El producto no existe.');
    }
    final result = await getById(id);
    if (result == null) {
      throw const NotFoundException('El producto no existe.');
    }
    return result;
  }

  @override
  Future<void> setActive(int id, bool active) async {
    final db = await _appDatabase.database;
    final updated = await db.update(
      'products',
      {'active': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (updated == 0) {
      throw const NotFoundException('El producto no existe.');
    }
  }

  @override
  Future<void> deleteIfUnused(int id) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      final movements = await txn.rawQuery(
        'SELECT COUNT(*) AS total FROM movements WHERE product_id = ?',
        [id],
      );
      final total = (movements.first['total'] as num).toInt();
      if (total > 0) {
        throw const ProductHasMovementsException();
      }
      final deleted = await txn.delete('products', where: 'id = ?', whereArgs: [id]);
      if (deleted == 0) {
        throw const NotFoundException('El producto no existe.');
      }
    });
  }

  @override
  Future<Category> createCategory(String name) async {
    final db = await _appDatabase.database;
    final id = await db.insert(
      'categories',
      {'name': name.trim()},
    );
    return Category(id: id, name: name.trim());
  }
}
