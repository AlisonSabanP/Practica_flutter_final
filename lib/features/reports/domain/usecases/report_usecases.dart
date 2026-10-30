import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../services/inventory_summary.dart';

class GetInventorySummary {
  const GetInventorySummary(this._repository);

  final ProductRepository _repository;

  Future<InventorySummary> call() async {
    final products = await _repository.getAll();
    return InventorySummary.fromProducts(products);
  }
}

class GetInventoryProducts {
  const GetInventoryProducts(this._repository);

  final ProductRepository _repository;

  Future<List<Product>> call({bool onlyActive = false}) async {
    final products = await _repository.getAll(includeInactive: !onlyActive);
    return [...products]..sort((a, b) => a.name.compareTo(b.name));
  }
}

class GetLowStockProducts {
  const GetLowStockProducts(this._repository);

  final ProductRepository _repository;

  Future<List<Product>> call() async {
    final products = await _repository.getBelowMinimumStock();
    return [...products]..sort((a, b) => a.currentStock.compareTo(b.currentStock));
  }
}
