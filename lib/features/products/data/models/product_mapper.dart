import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';

/// Mapeo entre filas SQLite y entidades de dominio de productos.
abstract final class ProductMapper {
  static const String selectWithCategory = '''
SELECT p.*, c.name AS category_name
FROM products p
LEFT JOIN categories c ON c.id = p.category_id
''';

  static Product fromRow(Map<String, Object?> row) {
    return Product(
      id: row['id'] as int?,
      code: row['code'] as String,
      name: row['name'] as String,
      description: (row['description'] as String?) ?? '',
      categoryId: row['category_id'] as int?,
      categoryName: row['category_name'] as String?,
      purchasePrice: (row['purchase_price'] as num?)?.toDouble() ?? 0,
      salePrice: (row['sale_price'] as num?)?.toDouble() ?? 0,
      currentStock: (row['current_stock'] as num?)?.toInt() ?? 0,
      minimumStock: (row['minimum_stock'] as num?)?.toInt() ?? 0,
      photoPath: row['photo_path'] as String?,
      active: ((row['active'] as num?)?.toInt() ?? 1) == 1,
    );
  }

  static Map<String, Object?> toRow(Product product) {
    return {
      'code': product.code,
      'name': product.name,
      'description': product.description,
      'category_id': product.categoryId,
      'purchase_price': product.purchasePrice,
      'sale_price': product.salePrice,
      'current_stock': product.currentStock,
      'minimum_stock': product.minimumStock,
      'photo_path': product.photoPath,
      'active': product.active ? 1 : 0,
    };
  }

  /// Mapa usado al crear un producto: el stock inicial nunca se escribe de
  /// forma directa, se registra como movimiento de entrada.
  static Map<String, Object?> toInsertRow(Product product) {
    final row = toRow(product);
    row['current_stock'] = 0;
    return row;
  }

  static Category categoryFromRow(Map<String, Object?> row) {
    return Category(id: row['id'] as int, name: row['name'] as String);
  }
}
