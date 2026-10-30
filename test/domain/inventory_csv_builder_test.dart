import 'package:flutter_test/flutter_test.dart';
import 'package:inventario/features/inventory/domain/entities/movement.dart';
import 'package:inventario/features/inventory/domain/entities/movement_type.dart';
import 'package:inventario/features/products/domain/entities/product.dart';
import 'package:inventario/features/reports/domain/services/inventory_csv_builder.dart';

void main() {
  group('InventoryCsvBuilder.buildInventory', () {
    test('incluye el encabezado y una fila por producto', () {
      final csv = InventoryCsvBuilder.buildInventory([
        const Product(
          id: 1,
          code: 'ABR-001',
          name: 'Arroz blanco 1 kg',
          categoryName: 'Abarrotes',
          purchasePrice: 4.2,
          salePrice: 5.9,
          currentStock: 40,
          minimumStock: 10,
        ),
      ]);
      final lines = csv.trim().split('\n');
      expect(lines.first, contains('codigo;nombre;categoria'));
      expect(lines, hasLength(2));
      expect(lines[1], contains('ABR-001'));
      expect(lines[1], contains('Arroz blanco 1 kg'));
      expect(lines[1], contains('activo'));
    });

    test('calcula el valor del inventario como stock por precio de compra',
        () {
      final csv = InventoryCsvBuilder.buildInventory([
        const Product(
          code: 'ABR-002',
          name: 'Azucar',
          purchasePrice: 3.8,
          salePrice: 5.2,
          currentStock: 35,
          minimumStock: 10,
        ),
      ]);
      expect(csv, contains('133.00'));
    });

    test('marca los productos desactivados como inactivos', () {
      final csv = InventoryCsvBuilder.buildInventory([
        const Product(
          code: 'ABR-003',
          name: 'Aceite',
          purchasePrice: 6.5,
          salePrice: 8.9,
          minimumStock: 8,
          active: false,
        ),
      ]);
      expect(csv, contains('inactivo'));
    });
  });

  group('InventoryCsvBuilder.buildMovements', () {
    test('incluye el tipo, el motivo y el responsable', () {
      final csv = InventoryCsvBuilder.buildMovements([
        Movement(
          id: 1,
          productId: 1,
          productCode: 'ABR-001',
          productName: 'Arroz',
          type: MovementType.salida,
          quantity: 16,
          previousStock: 20,
          resultingStock: 4,
          reason: 'Venta',
          responsible: 'Administrador',
          dateTime: DateTime(2026, 10, 30, 11, 30),
        ),
      ]);
      final lines = csv.trim().split('\n');
      expect(lines.first, contains('fecha_hora;codigo;producto;tipo'));
      expect(lines[1], contains('salida'));
      expect(lines[1], contains('Venta'));
      expect(lines[1], contains('Administrador'));
      expect(lines[1], contains('2026-10-30 11:30:00'));
    });
  });

  group('InventoryCsvBuilder.encode', () {
    test('usa punto y coma como separador', () {
      final csv = InventoryCsvBuilder.encode([
        ['a', 'b', 'c'],
      ]);
      expect(csv.trim(), 'a;b;c');
    });

    test('escapa los campos que contienen el separador', () {
      final csv = InventoryCsvBuilder.encode([
        ['Producto con; punto y coma', 'normal'],
      ]);
      expect(csv.trim(), '"Producto con; punto y coma";normal');
    });

    test('duplica las comillas internas', () {
      final csv = InventoryCsvBuilder.encode([
        ['Producto con "comillas"', 'normal'],
      ]);
      expect(csv.trim(), '"Producto con ""comillas""";normal');
    });

    test('escapa los saltos de linea', () {
      final csv = InventoryCsvBuilder.encode([
        ['linea uno\nlinea dos', 'normal'],
      ]);
      expect(csv, contains('"linea uno\nlinea dos";normal'));
    });
  });
}
