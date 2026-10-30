import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/usecases/product_usecases.dart';
import '../providers/product_providers.dart';
import '../widgets/product_tile.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

/// Listado de productos con busqueda y filtros por existencias y categoria.
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(productListProvider).filter.query,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider);
    final notifier = ref.read(productListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: notifier.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute<bool>(builder: (_) => const ProductFormScreen()),
          );
          if (created == true) await notifier.load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: notifier.setQuery,
              decoration: InputDecoration(
                hintText: 'Buscar por codigo, nombre o categoria',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.filter.query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar busqueda',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          notifier.setQuery('');
                        },
                      ),
              ),
            ),
          ),
          _FilterBar(state: state, notifier: notifier),
          const Divider(height: 1),
          Expanded(
            child: state.isLoading
                ? const LoadingView(message: 'Cargando productos')
                : state.error != null
                    ? ErrorView(message: state.error!, onRetry: notifier.load)
                    : state.products.isEmpty
                        ? EmptyState(
                            title: state.filter.hasActiveFilters
                                ? 'Sin resultados'
                                : 'Sin productos registrados',
                            message: state.filter.hasActiveFilters
                                ? 'Ajusta la busqueda o los filtros aplicados.'
                                : 'Registra el primer producto para comenzar a controlar el inventario.',
                            icon: Icons.inventory_2_outlined,
                            actionLabel: state.filter.hasActiveFilters
                                ? 'Limpiar filtros'
                                : 'Nuevo producto',
                            onAction: state.filter.hasActiveFilters
                                ? notifier.clearFilters
                                : () async {
                                    final created =
                                        await Navigator.of(context).push<bool>(
                                      MaterialPageRoute<bool>(
                                        builder: (_) => const ProductFormScreen(),
                                      ),
                                    );
                                    if (created == true) await notifier.load();
                                  },
                          )
                        : RefreshIndicator(
                            onRefresh: notifier.load,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                              itemCount: state.products.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppTheme.gap),
                              itemBuilder: (context, index) {
                                final product = state.products[index];
                                return ProductTile(
                                  product: product,
                                  onTap: () async {
                                    await Navigator.of(context).push<void>(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ProductDetailScreen(
                                          productId: product.id!,
                                        ),
                                      ),
                                    );
                                    await notifier.load();
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.state, required this.notifier});

  final ProductListState state;
  final ProductListNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Stock bajo'),
            selected: state.filter.stock == StockFilter.lowStock,
            onSelected: (value) => notifier.setStockFilter(
              value ? StockFilter.lowStock : StockFilter.all,
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Agotados'),
            selected: state.filter.stock == StockFilter.outOfStock,
            onSelected: (value) => notifier.setStockFilter(
              value ? StockFilter.outOfStock : StockFilter.all,
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Solo activos'),
            selected: state.filter.onlyActive,
            onSelected: (_) => notifier.toggleOnlyActive(),
          ),
          const SizedBox(width: 8),
          for (final category in state.categories) ...[
            FilterChip(
              label: Text(category.name),
              selected: state.filter.categoryId == category.id,
              onSelected: (value) =>
                  notifier.setCategory(value ? category.id : null),
            ),
            const SizedBox(width: 8),
          ],
          if (state.filter.hasActiveFilters)
            TextButton.icon(
              onPressed: notifier.clearFilters,
              icon: const Icon(Icons.filter_alt_off, size: 18),
              label: const Text('Limpiar'),
            ),
        ],
      ),
    );
  }
}
