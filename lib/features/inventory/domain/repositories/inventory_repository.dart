import '../../../products/domain/entities/product.dart';
import '../entities/movement.dart';
import '../entities/movement_type.dart';

/// Contrato del repositorio de inventario. Implementa en la capa data.
abstract interface class InventoryRepository {
  /// Registra el movimiento y actualiza el stock del producto en una sola
  /// operacion atomica. Devuelve el movimiento persistido y el producto
  /// actualizado.
  Future<MovementResult> registerMovement({
    required int productId,
    required MovementType type,
    required int quantity,
    required String reason,
    required String responsible,
  });

  Future<List<Movement>> getMovements({MovementFilter filter = const MovementFilter()});

  Future<List<Movement>> getMovementsForProduct(int productId, {int limit = 50});

  Future<int> countMovementsForProduct(int productId);

  Future<List<Movement>> getRecentMovements({int limit = 10});
}

/// Resultado de registrar un movimiento: el movimiento creado y el producto con
/// el stock ya actualizado.
class MovementResult {
  const MovementResult({required this.movement, required this.product});

  final Movement movement;
  final Product product;
}
