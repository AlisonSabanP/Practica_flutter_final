import 'movement_type.dart';

/// Motivos sugeridos por tipo de movimiento. La lista es orientativa; el
/// usuario puede escribir un motivo libre.
abstract final class MovementReasons {
  static const List<String> entry = [
    'Compra a proveedor',
    'Devolucion de cliente',
    'Reposicion de bodega',
    'Correccion de conteo',
  ];

  static const List<String> exit = [
    'Venta',
    'Producto danado',
    'Producto vencido',
    'Traslado a bodega',
    'Uso interno',
  ];

  static const List<String> adjustment = [
    'Conteo fisico',
    'Merma',
    'Correccion de digitacion',
  ];

  static List<String> forType(MovementType type) => switch (type) {
        MovementType.entrada => entry,
        MovementType.salida => exit,
        MovementType.ajuste => adjustment,
      };
}

/// Movimiento de inventario confirmado. Es inmutable: los errores se corrigen
/// con un movimiento nuevo, nunca editando o borrando el existente.
class Movement {
  const Movement({
    this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.resultingStock,
    this.reason = '',
    this.responsible = '',
    required this.dateTime,
    this.productName,
    this.productCode,
  });

  final int? id;
  final int productId;
  final MovementType type;

  /// Cantidad del movimiento. En un ajuste es el stock contado final.
  final int quantity;
  final int previousStock;
  final int resultingStock;
  final String reason;
  final String responsible;
  final DateTime dateTime;

  /// Datos de producto resueltos en la consulta. No se persisten en la tabla.
  final String? productName;
  final String? productCode;

  /// Diferencia aplicada sobre el stock (positiva o negativa). En un ajuste es
  /// la variacion real respecto al stock anterior.
  int get delta => resultingStock - previousStock;

  @override
  bool operator ==(Object other) =>
      other is Movement &&
      other.id == id &&
      other.productId == productId &&
      other.type == type &&
      other.quantity == quantity &&
      other.previousStock == previousStock &&
      other.resultingStock == resultingStock &&
      other.reason == reason &&
      other.responsible == responsible &&
      other.dateTime == dateTime;

  @override
  int get hashCode => Object.hash(id, productId, type, quantity, previousStock,
      resultingStock, reason, responsible, dateTime);

  @override
  String toString() =>
      'Movement($id, product: $productId, ${type.storageValue}, $quantity, '
      '$previousStock -> $resultingStock)';
}

/// Filtro de consulta del historial de movimientos.
class MovementFilter {
  const MovementFilter({
    this.productId,
    this.type,
    this.from,
    this.to,
  });

  final int? productId;
  final MovementType? type;
  final DateTime? from;
  final DateTime? to;

  bool get isEmpty => productId == null && type == null && from == null && to == null;

  MovementFilter copyWith({
    int? productId,
    MovementType? type,
    DateTime? from,
    DateTime? to,
    bool clearProduct = false,
    bool clearType = false,
    bool clearFrom = false,
    bool clearTo = false,
  }) {
    return MovementFilter(
      productId: clearProduct ? null : (productId ?? this.productId),
      type: clearType ? null : (type ?? this.type),
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
    );
  }
}
