/// Categoria de productos. Entidad de dominio pura.
class Category {
  const Category({required this.id, required this.name});

  final int id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is Category && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'Category($id, $name)';
}
