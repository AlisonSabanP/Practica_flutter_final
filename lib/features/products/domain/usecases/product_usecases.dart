import '../../../../core/errors/app_exception.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';
import '../services/product_validator.dart';

/// Lista los productos aplicando el termino de busqueda y el filtro de
/// existencias bajas. Regla de negocio pura de seleccion.
class GetProducts {
  const GetProducts(this._repository);

  final ProductRepository _repository;

  Future<List<Product>> call({
    String query = '',
    StockFilter stockFilter = StockFilter.all,
    bool onlyActive = false,
  }) async {
    final term = query.trim();
    var products = term.isEmpty
        ? await _repository.getAll(includeInactive: !onlyActive)
        : await _repository.search(term, includeInactive: !onlyActive);

    products = switch (stockFilter) {
      StockFilter.all => products,
      StockFilter.lowStock => products.where((p) => p.isBelowMinimum).toList(),
      StockFilter.outOfStock => products.where((p) => p.isOutOfStock).toList(),
    };

    final sorted = [...products]..sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }
}

enum StockFilter { all, lowStock, outOfStock }

/// Crea un producto validando unicidad de codigo y registrando el stock
/// inicial como movimiento de entrada.
class CreateProduct {
  const CreateProduct(this._repository);

  final ProductRepository _repository;

  Future<Product> call(
    Product product, {
    int initialStock = 0,
    String responsible = '',
  }) async {
    final normalized = product.copyWith(
      code: product.code.trim(),
      name: product.name.trim(),
    );
    ProductValidator.assertValid(normalized);

    final available = await _repository.isCodeAvailable(normalized.code);
    if (!available) throw DuplicateCodeException(normalized.code);

    return _repository.create(
      normalized,
      initialStock: initialStock,
      responsible: responsible.trim(),
    );
  }
}

/// Actualiza un producto existente. El stock solo cambia mediante movimientos,
/// por lo que el valor recibido en [product] se ignora en la persistencia.
class UpdateProduct {
  const UpdateProduct(this._repository);

  final ProductRepository _repository;

  Future<Product> call(Product product) async {
    if (product.id == null) {
      throw const ValidationException('El producto no tiene identificador.');
    }
    final normalized = product.copyWith(
      code: product.code.trim(),
      name: product.name.trim(),
    );
    ProductValidator.assertValid(normalized);

    final available = await _repository.isCodeAvailable(
      normalized.code,
      excludingProductId: normalized.id,
    );
    if (!available) throw DuplicateCodeException(normalized.code);

    return _repository.update(normalized);
  }
}

/// Desactiva o reactiva un producto sin borrar su historial.
class SetProductActive {
  const SetProductActive(this._repository);

  final ProductRepository _repository;

  Future<void> call(int productId, bool active) =>
      _repository.setActive(productId, active);
}

/// Elimina un producto solo si no tiene movimientos. Si los tiene, lanza
/// [ProductHasMovementsException] y la capa de presentacion ofrece desactivar.
class DeleteProduct {
  const DeleteProduct(this._repository);

  final ProductRepository _repository;

  Future<void> call(int productId) => _repository.deleteIfUnused(productId);
}

class GetProductByCode {
  const GetProductByCode(this._repository);

  final ProductRepository _repository;

  Future<Product?> call(String code) async {
    final value = code.trim();
    if (value.isEmpty) return null;
    return _repository.getByCode(value);
  }
}

class GetProductById {
  const GetProductById(this._repository);

  final ProductRepository _repository;

  Future<Product?> call(int id) => _repository.getById(id);
}
