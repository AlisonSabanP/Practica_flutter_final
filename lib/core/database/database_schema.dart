/// Sentencias SQL del esquema local. Se centralizan aqui para que las
/// migraciones y los repositorios compartan la misma definicion.
abstract final class DatabaseSchema {
  static const int version = 1;
  static const String fileName = 'inventario.db';

  static const String createCategories = '''
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
)''';

  static const String createProducts = '''
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
  purchase_price REAL NOT NULL DEFAULT 0,
  sale_price REAL NOT NULL DEFAULT 0,
  current_stock INTEGER NOT NULL DEFAULT 0 CHECK (current_stock >= 0),
  minimum_stock INTEGER NOT NULL DEFAULT 0 CHECK (minimum_stock >= 0),
  photo_path TEXT,
  active INTEGER NOT NULL DEFAULT 1
)''';

  static const String createMovements = '''
CREATE TABLE movements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
  type TEXT NOT NULL CHECK (type IN ('entrada','salida','ajuste')),
  quantity INTEGER NOT NULL,
  previous_stock INTEGER NOT NULL,
  resulting_stock INTEGER NOT NULL CHECK (resulting_stock >= 0),
  reason TEXT NOT NULL DEFAULT '',
  responsible TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL
)''';

  static const List<String> createIndexes = [
    'CREATE INDEX idx_products_code ON products(code)',
    'CREATE INDEX idx_products_category ON products(category_id)',
    'CREATE INDEX idx_movements_product ON movements(product_id)',
    'CREATE INDEX idx_movements_created ON movements(created_at)',
  ];

  static const String createProfile = '''
CREATE TABLE profile (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)''';

  static const List<String> createStatements = [
    createCategories,
    createProducts,
    createMovements,
    createProfile,
    ...createIndexes,
  ];
}
