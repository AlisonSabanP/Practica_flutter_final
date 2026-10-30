/// Producto de la tienda o bodega. Entidad de dominio pura.
class Product {
  const Product({
    this.id,
    required this.code,
    required this.name,
    this.description = '',
    this.categoryId,
    this.categoryName,
    required this.purchasePrice,
    required this.salePrice,
    this.currentStock = 0,
    required this.minimumStock,
    this.photoPath,
    this.active = true,
  });

  final int? id;

  /// Codigo unico del producto. Es el contenido del codigo de barras y del QR.
  final String code;
  final String name;
  final String description;
  final int? categoryId;

  /// Nombre de la categoria resuelto en la consulta. No se persiste en la tabla.
  final String? categoryName;
  final double purchasePrice;
  final double salePrice;
  final int currentStock;
  final int minimumStock;
  final String? photoPath;
  final bool active;

  bool get isNew => id == null;

  bool get isBelowMinimum => currentStock <= minimumStock;

  bool get isOutOfStock => currentStock <= 0;

  double get inventoryValue => currentStock * purchasePrice;

  Product copyWith({
    int? id,
    String? code,
    String? name,
    String? description,
    int? categoryId,
    String? categoryName,
    double? purchasePrice,
    double? salePrice,
    int? currentStock,
    int? minimumStock,
    String? photoPath,
    bool? active,
    bool clearPhoto = false,
    bool clearCategory = false,
  }) {
    return Product(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      categoryName: clearCategory ? null : (categoryName ?? this.categoryName),
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      active: active ?? this.active,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Product &&
      other.id == id &&
      other.code == code &&
      other.name == name &&
      other.description == description &&
      other.categoryId == categoryId &&
      other.purchasePrice == purchasePrice &&
      other.salePrice == salePrice &&
      other.currentStock == currentStock &&
      other.minimumStock == minimumStock &&
      other.photoPath == photoPath &&
      other.active == active;

  @override
  int get hashCode => Object.hash(id, code, name, description, categoryId,
      purchasePrice, salePrice, currentStock, minimumStock, photoPath, active);

  @override
  String toString() => 'Product($id, $code, $name, stock: $currentStock)';
}
