import '../../../../core/database/app_database.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../products/data/models/product_mapper.dart';
import '../../domain/entities/movement.dart';
import '../../domain/entities/movement_type.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/services/stock_calculator.dart';

/// Implementacion sqflite del repositorio de inventario. El registro del
/// movimiento y la actualizacion del stock se ejecutan dentro de la misma
/// transaccion, de modo que la operacion es atomica.
class SqliteInventoryRepository implements InventoryRepository {
  SqliteInventoryRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  static const String _selectWithProduct = '''
SELECT m.*, p.name AS product_name, p.code AS product_code
FROM movements m
INNER JOIN products p ON p.id = m.product_id
''';

  @override
  Future<MovementResult> registerMovement({
    required int productId,
    required MovementType type,
    required int quantity,
    required String reason,
    required String responsible,
  }) async {
    final db = await _appDatabase.database;
    return db.transaction<MovementResult>((txn) async {
      // La lectura del stock se hace dentro de la transaccion para que el
      // calculo use el valor mas reciente y no uno obsoleto.
      final rows = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw const NotFoundException('El producto no existe.');
      }
      final product = ProductMapper.fromRow(rows.first);

      final calculation = StockCalculator.apply(
        type: type,
        previousStock: product.currentStock,
        quantity: quantity,
        reason: reason,
        productName: product.name,
      );

      final updated = await txn.update(
        'products',
        {'current_stock': calculation.resultingStock},
        where: 'id = ? AND current_stock = ?',
        whereArgs: [productId, product.currentStock],
      );
      if (updated != 1) {
        throw const StorageException(
          'El stock cambio durante la operacion. Intenta de nuevo.',
        );
      }

      final movementId = await txn.insert('movements', {
        'product_id': productId,
        'type': type.storageValue,
        'quantity': calculation.quantity,
        'previous_stock': calculation.previousStock,
        'resulting_stock': calculation.resultingStock,
        'reason': reason.trim(),
        'responsible': responsible.trim(),
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      final movementRows = await txn.query(
        'movements',
        where: 'id = ?',
        whereArgs: [movementId],
        limit: 1,
      );
      final movement = MovementMapper.fromRow(movementRows.first).copyWithProduct(
        name: product.name,
        code: product.code,
      );

      return MovementResult(
        movement: movement,
        product: product.copyWith(currentStock: calculation.resultingStock),
      );
    });
  }

  @override
  Future<List<Movement>> getMovements({
    MovementFilter filter = const MovementFilter(),
  }) async {
    final db = await _appDatabase.database;
    final where = <String>[];
    final args = <Object?>[];

    if (filter.productId != null) {
      where.add('m.product_id = ?');
      args.add(filter.productId);
    }
    if (filter.type != null) {
      where.add('m.type = ?');
      args.add(filter.type!.storageValue);
    }
    if (filter.from != null) {
      where.add('m.created_at >= ?');
      args.add(_startOfDay(filter.from!).millisecondsSinceEpoch);
    }
    if (filter.to != null) {
      where.add('m.created_at <= ?');
      args.add(_endOfDay(filter.to!).millisecondsSinceEpoch);
    }

    final rows = await db.rawQuery(
      '$_selectWithProduct'
      '${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')} '}'
      'ORDER BY m.created_at DESC, m.id DESC',
      args,
    );
    return rows.map(MovementMapper.fromRow).toList();
  }

  @override
  Future<List<Movement>> getMovementsForProduct(int productId, {int limit = 50}) async {
    final db = await _appDatabase.database;
    final rows = await db.rawQuery(
      '$_selectWithProduct'
      'WHERE m.product_id = ? '
      'ORDER BY m.created_at DESC, m.id DESC LIMIT ?',
      [productId, limit],
    );
    return rows.map(MovementMapper.fromRow).toList();
  }

  @override
  Future<int> countMovementsForProduct(int productId) async {
    final db = await _appDatabase.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM movements WHERE product_id = ?',
      [productId],
    );
    return (rows.first['total'] as num).toInt();
  }

  @override
  Future<List<Movement>> getRecentMovements({int limit = 10}) async {
    final db = await _appDatabase.database;
    final rows = await db.rawQuery(
      '$_selectWithProduct ORDER BY m.created_at DESC, m.id DESC LIMIT ?',
      [limit],
    );
    return rows.map(MovementMapper.fromRow).toList();
  }

  static DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime _endOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
}

/// Mapeo entre filas SQLite y la entidad Movement.
abstract final class MovementMapper {
  static Movement fromRow(Map<String, Object?> row) {
    return Movement(
      id: row['id'] as int?,
      productId: row['product_id'] as int,
      type: MovementType.fromStorage(row['type'] as String),
      quantity: (row['quantity'] as num).toInt(),
      previousStock: (row['previous_stock'] as num).toInt(),
      resultingStock: (row['resulting_stock'] as num).toInt(),
      reason: (row['reason'] as String?) ?? '',
      responsible: (row['responsible'] as String?) ?? '',
      dateTime: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as num).toInt(),
      ),
      productName: row['product_name'] as String?,
      productCode: row['product_code'] as String?,
    );
  }
}

extension on Movement {
  Movement copyWithProduct({required String name, required String code}) {
    return Movement(
      id: id,
      productId: productId,
      type: type,
      quantity: quantity,
      previousStock: previousStock,
      resultingStock: resultingStock,
      reason: reason,
      responsible: responsible,
      dateTime: dateTime,
      productName: name,
      productCode: code,
    );
  }
}
