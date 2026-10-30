import 'package:flutter_test/flutter_test.dart';
import 'package:inventario/core/errors/app_exception.dart';
import 'package:inventario/features/inventory/domain/entities/movement_type.dart';
import 'package:inventario/features/inventory/domain/services/stock_calculator.dart';

void main() {
  group('StockCalculator entrada', () {
    test('suma la cantidad al stock actual', () {
      final result = StockCalculator.apply(
        type: MovementType.entrada,
        previousStock: 10,
        quantity: 20,
        reason: 'Compra a proveedor',
      );

      expect(result.previousStock, 10);
      expect(result.resultingStock, 30);
      expect(result.quantity, 20);
      expect(result.delta, 20);
    });

    test('rechaza cantidad cero', () {
      expect(
        () => StockCalculator.apply(
          type: MovementType.entrada,
          previousStock: 10,
          quantity: 0,
          reason: 'Compra',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rechaza cantidad negativa', () {
      expect(
        () => StockCalculator.apply(
          type: MovementType.entrada,
          previousStock: 10,
          quantity: -3,
          reason: 'Compra',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('exige motivo no vacio', () {
      expect(
        () => StockCalculator.apply(
          type: MovementType.entrada,
          previousStock: 0,
          quantity: 5,
          reason: '   ',
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('StockCalculator salida', () {
    test('resta la cantidad cuando hay existencias suficientes', () {
      final result = StockCalculator.apply(
        type: MovementType.salida,
        previousStock: 20,
        quantity: 16,
        reason: 'Venta',
      );

      expect(result.resultingStock, 4);
      expect(result.delta, -16);
    });

    test('permite dejar el stock exactamente en cero', () {
      final result = StockCalculator.apply(
        type: MovementType.salida,
        previousStock: 4,
        quantity: 4,
        reason: 'Venta',
      );

      expect(result.resultingStock, 0);
    });

    test('impide retirar mas unidades que las disponibles', () {
      expect(
        () => StockCalculator.apply(
          type: MovementType.salida,
          previousStock: 4,
          quantity: 5,
          reason: 'Venta',
        ),
        throwsA(
          isA<InsufficientStockException>()
              .having((e) => e.available, 'available', 4)
              .having((e) => e.requested, 'requested', 5),
        ),
      );
    });

    test('rechaza cantidad cero', () {
      expect(
        () => StockCalculator.apply(
          type: MovementType.salida,
          previousStock: 10,
          quantity: 0,
          reason: 'Venta',
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('StockCalculator ajuste', () {
    test('fija el stock contado sin importar el valor anterior', () {
      final result = StockCalculator.apply(
        type: MovementType.ajuste,
        previousStock: 4,
        quantity: 3,
        reason: 'Conteo fisico',
      );

      expect(result.resultingStock, 3);
      expect(result.quantity, 3);
      expect(result.delta, -1);
    });

    test('acepta ajuste a cero con justificacion', () {
      final result = StockCalculator.apply(
        type: MovementType.ajuste,
        previousStock: 7,
        quantity: 0,
        reason: 'Producto perdido',
      );

      expect(result.resultingStock, 0);
    });

    test('exige justificacion no vacia', () {
      expect(
        () => StockCalculator.apply(
          type: MovementType.ajuste,
          previousStock: 10,
          quantity: 3,
          reason: '   ',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rechaza cantidad contada negativa', () {
      expect(
        () => StockCalculator.apply(
          type: MovementType.ajuste,
          previousStock: 10,
          quantity: -1,
          reason: 'Conteo',
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  test('rechaza stock previo negativo como inconsistencia de datos', () {
    expect(
      () => StockCalculator.apply(
        type: MovementType.entrada,
        previousStock: -1,
        quantity: 5,
        reason: 'Compra',
      ),
      throwsA(isA<StorageException>()),
    );
  });
}
