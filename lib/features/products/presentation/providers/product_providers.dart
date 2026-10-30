import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/product_usecases.dart';

/// Filtros aplicados al listado de productos.
class ProductFilter {
  const ProductFilter({
    this.query = '',
    this.stock = StockFilter.all,
    this.onlyActive = false,
    this.categoryId,
  });

  final String query;
  final StockFilter stock;
  final bool onlyActive;
  final int? categoryId;

  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      stock != StockFilter.all ||
      onlyActive ||
      categoryId != null;

  ProductFilter copyWith({
    String? query,
    StockFilter? stock,
    bool? onlyActive,
    int? categoryId,
    bool clearCategory = false,
  }) {
    return ProductFilter(
      query: query ?? this.query,
      stock: stock ?? this.stock,
      onlyActive: onlyActive ?? this.onlyActive,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    );
  }
}

/// Estado de la pantalla de productos: filtros y datos cargados.
class ProductListState {
  const ProductListState({
    this.filter = const ProductFilter(),
    this.products = const [],
    this.categories = const [],
    this.isLoading = true,
    this.error,
  });

  final ProductFilter filter;
  final List<Product> products;
  final List<Category> categories;
  final bool isLoading;
  final String? error;

  ProductListState copyWith({
    ProductFilter? filter,
    List<Product>? products,
    List<Category>? categories,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ProductListState(
      filter: filter ?? this.filter,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ProductListNotifier extends Notifier<ProductListState> {
  @override
  ProductListState build() {
    Future.microtask(load);
    return const ProductListState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final products = await ref.read(getProductsProvider).call(
            query: state.filter.query,
            stockFilter: state.filter.stock,
            onlyActive: state.filter.onlyActive,
          );
      final categories = await ref.read(productRepositoryProvider).getCategories();
      final filtered = state.filter.categoryId == null
          ? products
          : products.where((p) => p.categoryId == state.filter.categoryId).toList();
      state = state.copyWith(
        products: filtered,
        categories: categories,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> setQuery(String query) async {
    state = state.copyWith(filter: state.filter.copyWith(query: query));
    await load();
  }

  Future<void> setStockFilter(StockFilter filter) async {
    state = state.copyWith(filter: state.filter.copyWith(stock: filter));
    await load();
  }

  Future<void> setCategory(int? categoryId) async {
    state = state.copyWith(
      filter: categoryId == null
          ? state.filter.copyWith(clearCategory: true)
          : state.filter.copyWith(categoryId: categoryId),
    );
    await load();
  }

  Future<void> toggleOnlyActive() async {
    state = state.copyWith(
      filter: state.filter.copyWith(onlyActive: !state.filter.onlyActive),
    );
    await load();
  }

  Future<void> clearFilters() async {
    state = state.copyWith(filter: const ProductFilter());
    await load();
  }
}

final productListProvider =
    NotifierProvider<ProductListNotifier, ProductListState>(ProductListNotifier.new);

/// Detalle de un producto por identificador. Se refresca al invalidar.
final productDetailProvider = FutureProvider.family<Product?, int>((ref, id) {
  return ref.watch(getProductByIdProvider).call(id);
});

/// Categorias disponibles para el formulario de producto.
final categoriesProvider = FutureProvider((ref) {
  return ref.watch(productRepositoryProvider).getCategories();
});
