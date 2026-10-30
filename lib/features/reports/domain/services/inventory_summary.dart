import '../../../products/domain/entities/product.dart';

/// Resumen agregado del inventario usado en la pantalla de inicio y reportes.
class InventorySummary {
  const InventorySummary({
    required this.totalProducts,
    required this.activeProducts,
    required this.inactiveProducts,
    required this.totalUnits,
    required this.inventoryValue,
    required this.lowStockCount,
    required this.outOfStockCount,
  });

  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;
  final int totalUnits;
  final double inventoryValue;
  final int lowStockCount;
  final int outOfStockCount;

  static const empty = InventorySummary(
    totalProducts: 0,
    activeProducts: 0,
    inactiveProducts: 0,
    totalUnits: 0,
    inventoryValue: 0,
    lowStockCount: 0,
    outOfStockCount: 0,
  );

  /// Calcula el resumen a partir de la lista de productos. El valor del
  /// inventario es una estimacion simple: existencias x precio de compra.
  factory InventorySummary.fromProducts(List<Product> products) {
    var totalUnits = 0;
    var inventoryValue = 0.0;
    var lowStock = 0;
    var outOfStock = 0;
    var active = 0;

    for (final product in products) {
      totalUnits += product.currentStock;
      inventoryValue += product.inventoryValue;
      if (product.isBelowMinimum) lowStock++;
      if (product.isOutOfStock) outOfStock++;
      if (product.active) active++;
    }

    return InventorySummary(
      totalProducts: products.length,
      activeProducts: active,
      inactiveProducts: products.length - active,
      totalUnits: totalUnits,
      inventoryValue: inventoryValue,
      lowStockCount: lowStock,
      outOfStockCount: outOfStock,
    );
  }
}
