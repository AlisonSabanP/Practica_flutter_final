import '../entities/category.dart';
import '../entities/product.dart';

abstract interface class ProductRepository {
  Future<List<Product>> getAll({bool includeInactive = true});

  Future<List<Product>> search(String term, {bool includeInactive = false});

  Future<Product?> getById(int id);

  Future<Product?> getByCode(String code);

  Future<List<Product>> getBelowMinimumStock();

  Future<List<Category>> getCategories();

  /// Devuelve true si [code] esta libre. Si [excludingProductId] se indica, se
  /// ignora ese producto en la comprobacion (caso de edicion).
  Future<bool> isCodeAvailable(String code, {int? excludingProductId});

  Future<int> countAll();

  Future<int> countBelowMinimumStock();

  Future<double> inventoryValue();

  /// Crea el producto y, si [initialStock] es mayor que cero, registra el
  /// movimiento de entrada inicial en la misma transaccion.
  Future<Product> create(Product product, {int initialStock = 0, String responsible = ''});

  Future<Product> update(Product product);

  Future<void> setActive(int id, bool active);

  /// Elimina fisicamente solo si no tiene movimientos. En caso contrario lanza
  /// [ProductHasMovementsException].
  Future<void> deleteIfUnused(int id);

  Future<Category> createCategory(String name);
}
