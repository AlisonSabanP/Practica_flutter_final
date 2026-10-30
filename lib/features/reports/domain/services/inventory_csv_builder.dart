import '../../../products/domain/entities/product.dart';
import '../../../inventory/domain/entities/movement.dart';

/// Genera el contenido CSV del inventario y del historial de movimientos.
/// Es dominio puro: no escribe archivos, solo produce texto.
abstract final class InventoryCsvBuilder {
  static const List<String> inventoryHeaders = [
    'codigo',
    'nombre',
    'categoria',
    'precio_compra',
    'precio_venta',
    'stock_actual',
    'stock_minimo',
    'valor_inventario',
    'estado',
  ];

  static const List<String> movementHeaders = [
    'fecha_hora',
    'codigo',
    'producto',
    'tipo',
    'cantidad',
    'stock_anterior',
    'stock_resultante',
    'motivo',
    'responsable',
  ];

  static String buildInventory(List<Product> products) {
    final rows = <List<String>>[
      inventoryHeaders,
      for (final product in products)
        [
          product.code,
          product.name,
          product.categoryName ?? 'Sin categoria',
          _decimal(product.purchasePrice),
          _decimal(product.salePrice),
          product.currentStock.toString(),
          product.minimumStock.toString(),
          _decimal(product.inventoryValue),
          product.active ? 'activo' : 'inactivo',
        ],
    ];
    return encode(rows);
  }

  static String buildMovements(List<Movement> movements) {
    final rows = <List<String>>[
      movementHeaders,
      for (final movement in movements)
        [
          formatDateTime(movement.dateTime),
          movement.productCode ?? '',
          movement.productName ?? '',
          movement.type.storageValue,
          movement.quantity.toString(),
          movement.previousStock.toString(),
          movement.resultingStock.toString(),
          movement.reason,
          movement.responsible,
        ],
    ];
    return encode(rows);
  }

  /// Codifica en CSV con separador punto y coma, que es el que abre
  /// correctamente Excel en configuracion regional en espanol.
  static String encode(List<List<String>> rows) {
    final buffer = StringBuffer();
    for (final row in rows) {
      buffer.writeln(row.map(_escape).join(';'));
    }
    return buffer.toString();
  }

  static String _escape(String value) {
    final needsQuotes = value.contains(';') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  static String _decimal(double value) => value.toStringAsFixed(2);

  static String inventoryFileName(DateTime now) => 'inventario_${_stamp(now)}.csv';

  static String movementsFileName(DateTime now) => 'movimientos_${_stamp(now)}.csv';

  static String _stamp(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}${two(value.month)}${two(value.day)}_'
        '${two(value.hour)}${two(value.minute)}';
  }

  static String formatDateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }
}
