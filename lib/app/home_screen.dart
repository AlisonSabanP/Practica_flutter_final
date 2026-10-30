import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_cards.dart';
import '../core/widgets/state_views.dart';
import '../features/inventory/presentation/providers/inventory_providers.dart';
import '../features/inventory/presentation/widgets/movement_tile.dart';
import '../features/products/presentation/screens/product_detail_screen.dart';
import '../features/products/presentation/screens/product_form_screen.dart';
import '../features/products/presentation/screens/products_screen.dart';
import '../features/products/presentation/widgets/product_tile.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/scanner/presentation/screens/scanner_screen.dart';
import '../features/settings/presentation/providers/profile_providers.dart';

/// Panel de inicio: resumen del inventario, alertas de stock y accesos rapidos.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(inventorySummaryProvider);
    final lowStock = ref.watch(lowStockProductsProvider);
    final recent = ref.watch(recentMovementsProvider);
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('INVENTARIO'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () {
              ref.invalidate(inventorySummaryProvider);
              ref.invalidate(lowStockProductsProvider);
              ref.invalidate(recentMovementsProvider);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: summary.when(
        loading: () => const LoadingView(message: 'Cargando inventario'),
        error: (error, _) => ErrorView(
          message: describeError(error),
          onRetry: () => ref.invalidate(inventorySummaryProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(inventorySummaryProvider);
            ref.invalidate(lowStockProductsProvider);
            ref.invalidate(recentMovementsProvider);
            await ref.read(inventorySummaryProvider.future);
          },
          child: ListView(
            padding: AppTheme.screenPadding,
            children: [
              if (!(profile.value?.initialized ?? false)) const _ProfileHint(),
              Text(
                'Responsable: ${profile.value?.responsibleName.isNotEmpty == true ? profile.value!.responsibleName : 'sin configurar'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                profile.value?.storeName.isNotEmpty == true
                    ? profile.value!.storeName
                    : 'Tienda y bodega',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppTheme.gap,
                crossAxisSpacing: AppTheme.gap,
                childAspectRatio: 1.55,
                children: [
                  MetricTile(
                    label: 'Productos activos',
                    value: '${data.activeProducts}',
                    icon: Icons.inventory_2_outlined,
                  ),
                  MetricTile(
                    label: 'Unidades en stock',
                    value: Formatters.integer(data.totalUnits),
                    icon: Icons.warehouse_outlined,
                  ),
                  MetricTile(
                    label: 'Valor del inventario',
                    value: Formatters.currency(data.inventoryValue),
                    icon: Icons.payments_outlined,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                  MetricTile(
                    label: 'Alertas de stock',
                    value: '${data.lowStockCount}',
                    icon: Icons.warning_amber_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.gap),
              const SectionHeader(title: 'Accesos rapidos'),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ProductFormScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Producto'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.gap),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ScannerScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Escanear'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.gap),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ReportsScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.assessment_outlined),
                      label: const Text('Reportes'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.gap),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ProductsScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.list_alt),
                      label: const Text('Listado'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.gap),
              const SectionHeader(title: 'Alertas de stock minimo'),
              lowStock.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: LoadingView(),
                ),
                error: (error, _) => ErrorView(message: describeError(error)),
                data: (products) => products.isEmpty
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Ningun producto esta por debajo del stock minimo.',
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (final product in products.take(5))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ProductTile(
                                product: product,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ProductDetailScreen(
                                      productId: product.id!,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: AppTheme.gap),
              const SectionHeader(title: 'Movimientos recientes'),
              recent.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: LoadingView(),
                ),
                error: (error, _) => ErrorView(message: describeError(error)),
                data: (movements) => movements.isEmpty
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Todavia no hay movimientos registrados.'),
                        ),
                      )
                    : Card(
                        child: Column(
                          children: [
                            for (var i = 0; i < movements.length; i++) ...[
                              MovementTile(movement: movements[i]),
                              if (i < movements.length - 1)
                                const Divider(height: 1),
                            ],
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHint extends StatelessWidget {
  const _ProfileHint();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.gap),
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Configura el nombre del responsable en la pestana Perfil para registrar movimientos.',
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
