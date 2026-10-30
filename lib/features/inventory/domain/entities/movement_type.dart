/// Tipo de movimiento de inventario.
enum MovementType {
  entrada('entrada'),
  salida('salida'),
  ajuste('ajuste');

  const MovementType(this.storageValue);

  final String storageValue;

  static MovementType fromStorage(String value) {
    return MovementType.values.firstWhere(
      (type) => type.storageValue == value,
      orElse: () => MovementType.ajuste,
    );
  }

  String get label => switch (this) {
        MovementType.entrada => 'Entrada',
        MovementType.salida => 'Salida',
        MovementType.ajuste => 'Ajuste',
      };

  /// Una entrada suma, una salida resta y un ajuste fija el valor contado.
  bool get isIncrease => this == MovementType.entrada;
  bool get isDecrease => this == MovementType.salida;
  bool get isAbsolute => this == MovementType.ajuste;
}
