import '../../../../core/errors/app_exception.dart';
import '../entities/movement_type.dart';

/// Resultado del calculo de existencias. Valor de dominio puro, sin dependencia
/// de la base de datos ni de la interfaz.
class StockCalculation {
  const StockCalculation({
    required this.previousStock,
    required this.resultingStock,
    required this.quantity,
  });

  final int previousStock;
  final int resultingStock;
  final int quantity;

  int get delta => resultingStock - previousStock;
}

/// Nucleo de las reglas de inventario. Todas las operaciones son funciones
/// puras: reciben el stock actual y los datos del movimiento, y devuelven el
/// stock resultante o lanzan [AppException].
abstract final class StockCalculator {
  static const int maxQuantity = 1000000;

  /// Valida y calcula el stock resultante de un movimiento.
  ///
  /// Reglas:
  /// - Entrada y salida exigen cantidad mayor que cero.
  /// - La salida no puede superar el stock disponible.
  /// - El ajuste registra el stock contado final y exige justificacion.
  /// - El motivo no puede estar vacio en ningun tipo.
  /// - El stock resultante nunca puede ser negativo.
  static StockCalculation apply({
    required MovementType type,
    required int previousStock,
    required int quantity,
    required String reason,
    String? productName,
  }) {
    if (previousStock < 0) {
      throw const StorageException(
        'El stock actual del producto es inconsistente (negativo).',
      );
    }

    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw const ValidationException(
        'El motivo del movimiento es obligatorio.',
        field: 'reason',
      );
    }

    switch (type) {
      case MovementType.entrada:
        _assertPositiveQuantity(quantity);
        return StockCalculation(
          previousStock: previousStock,
          resultingStock: previousStock + quantity,
          quantity: quantity,
        );

      case MovementType.salida:
        _assertPositiveQuantity(quantity);
        if (quantity > previousStock) {
          throw InsufficientStockException(
            available: previousStock,
            requested: quantity,
          );
        }
        return StockCalculation(
          previousStock: previousStock,
          resultingStock: previousStock - quantity,
          quantity: quantity,
        );

      case MovementType.ajuste:
        if (quantity < 0) {
          throw const ValidationException(
            'La cantidad contada no puede ser negativa.',
            field: 'quantity',
          );
        }
        if (quantity > maxQuantity) {
          throw const ValidationException(
            'La cantidad contada excede el maximo permitido.',
            field: 'quantity',
          );
        }
        if (trimmedReason.isEmpty) {
          throw const ValidationException(
            'El ajuste exige una justificacion.',
            field: 'reason',
          );
        }
        return StockCalculation(
          previousStock: previousStock,
          resultingStock: quantity,
          quantity: quantity,
        );
    }
  }

  static void _assertPositiveQuantity(int quantity) {
    if (quantity <= 0) {
      throw const ValidationException(
        'La cantidad debe ser mayor que cero.',
        field: 'quantity',
      );
    }
    if (quantity > maxQuantity) {
      throw const ValidationException(
        'La cantidad excede el maximo permitido.',
        field: 'quantity',
      );
    }
  }
}
