import '../../../../core/errors/app_exception.dart';
import '../../../products/domain/entities/product.dart';
import '../entities/movement.dart';
import '../entities/movement_type.dart';
import '../repositories/inventory_repository.dart';
import '../services/stock_calculator.dart';

/// Valida el movimiento con las reglas de inventario y delega el registro
/// atomico al repositorio. La actualizacion del stock y la insercion del
/// movimiento ocurren en una sola transaccion.
class RegisterMovement {
  const RegisterMovement(this._repository);

  final InventoryRepository _repository;

  Future<MovementResult> call({
    required Product product,
    required MovementType type,
    required int quantity,
    required String reason,
    required String responsible,
  }) async {
    final productId = product.id;
    if (productId == null) {
      throw const ValidationException('El producto no esta registrado.');
    }
    if (!product.active) {
      throw const ValidationException(
        'El producto esta desactivado. Reactivalo para registrar movimientos.',
      );
    }
    if (responsible.trim().isEmpty) {
      throw const ValidationException(
        'Configura el nombre del responsable en el perfil local.',
        field: 'responsible',
      );
    }

    StockCalculator.apply(
      type: type,
      previousStock: product.currentStock,
      quantity: quantity,
      reason: reason,
      productName: product.name,
    );

    return _repository.registerMovement(
      productId: productId,
      type: type,
      quantity: quantity,
      reason: reason.trim(),
      responsible: responsible.trim(),
    );
  }
}

class GetMovements {
  const GetMovements(this._repository);

  final InventoryRepository _repository;

  Future<List<Movement>> call({MovementFilter filter = const MovementFilter()}) =>
      _repository.getMovements(filter: filter);
}

class GetMovementsForProduct {
  const GetMovementsForProduct(this._repository);

  final InventoryRepository _repository;

  Future<List<Movement>> call(int productId, {int limit = 50}) =>
      _repository.getMovementsForProduct(productId, limit: limit);
}

class GetRecentMovements {
  const GetRecentMovements(this._repository);

  final InventoryRepository _repository;

  Future<List<Movement>> call({int limit = 10}) =>
      _repository.getRecentMovements(limit: limit);
}
