import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../inventory/domain/entities/movement_type.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../inventory/presentation/widgets/movement_tile.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../data/report_export_service.dart';
import '../../../../core/di/providers.dart';

/// Historial de movimientos con filtros y exportacion del inventario a CSV.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(inventorySummaryProvider);
    final movements = ref.watch(movementListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () {
              ref.invalidate(inventorySummaryProvider);
              ref.read(movementListProvider.notifier).load();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: AppTheme.screenPadding,
        children: [
          const SectionHeader(title: 'Valor del inventario'),
          summary.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: LoadingView(),
            ),
            error: (error, _) => ErrorView(
              message: describeError(error),
              onRetry: () => ref.invalidate(inventorySummaryProvider),
            ),
            data: (data) => Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valor estimado',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.currency(data.inventoryValue),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Calculado como existencias x precio de compra. '
                          'Estimacion simple, sin metodos contables.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.gap),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppTheme.gap,
                  crossAxisSpacing: AppTheme.gap,
                  childAspectRatio: 1.55,
                  children: [
                    MetricTile(
                      label: 'Productos',
                      value: '${data.totalProducts}',
                      icon: Icons.inventory_2_outlined,
                    ),
                    MetricTile(
                      label: 'Unidades totales',
                      value: Formatters.integer(data.totalUnits),
                      icon: Icons.warehouse_outlined,
                    ),
                    MetricTile(
                      label: 'Bajo minimo',
                      value: '${data.lowStockCount}',
                      icon: Icons.warning_amber_outlined,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    MetricTile(
                      label: 'Agotados',
                      value: '${data.outOfStockCount}',
                      icon: Icons.remove_shopping_cart_outlined,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.gap),
          const SectionHeader(title: 'Exportar'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  FilledButton.icon(
                    onPressed: _exporting ? null : _exportInventory,
                    icon: _exporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.table_view_outlined),
                    label: const Text('Exportar inventario a CSV'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _exporting ? null : _exportMovements,
                    icon: const Icon(Icons.history),
                    label: const Text('Exportar historial filtrado a CSV'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.gap),
          const SectionHeader(title: 'Historial de movimientos'),
          _MovementFilters(state: movements, notifier: ref.read(movementListProvider.notifier)),
          const SizedBox(height: AppTheme.gap),
          if (movements.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: LoadingView(message: 'Cargando historial'),
            )
          else if (movements.error != null)
            ErrorView(
              message: movements.error!,
              onRetry: ref.read(movementListProvider.notifier).load,
            )
          else if (movements.movements.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No hay movimientos que coincidan con los filtros aplicados.',
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < movements.movements.length; i++) ...[
                    MovementTile(movement: movements.movements[i]),
                    if (i < movements.movements.length - 1)
                      const Divider(height: 1),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _exportInventory() async {
    setState(() => _exporting = true);
    try {
      final products = await ref.read(getInventoryProductsProvider).call();
      await ref.read(reportExportServiceProvider).exportInventory(products);
      _showMessage('Inventario exportado (${products.length} productos).');
    } catch (error) {
      _showMessage(describeError(error));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportMovements() async {
    setState(() => _exporting = true);
    try {
      final state = ref.read(movementListProvider);
      if (state.movements.isEmpty) {
        _showMessage('No hay movimientos para exportar con los filtros actuales.');
        return;
      }
      await ref.read(reportExportServiceProvider).exportMovements(state.movements);
      _showMessage('Historial exportado (${state.movements.length} movimientos).');
    } catch (error) {
      _showMessage(describeError(error));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MovementFilters extends ConsumerWidget {
  const _MovementFilters({required this.state, required this.notifier});

  final MovementListState state;
  final MovementListNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productListProvider).products;
    final filter = state.filter;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int?>(
              initialValue: filter.productId,
              decoration: const InputDecoration(labelText: 'Producto'),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todos los productos'),
                ),
                for (final product in products)
                  DropdownMenuItem<int?>(
                    value: product.id,
                    child: Text('${product.code} - ${product.name}'),
                  ),
              ],
              onChanged: notifier.setProduct,
            ),
            const SizedBox(height: 10),
            SegmentedButton<MovementType?>(
              segments: const [
                ButtonSegment(value: null, label: Text('Todos')),
                ButtonSegment(value: MovementType.entrada, label: Text('Entradas')),
                ButtonSegment(value: MovementType.salida, label: Text('Salidas')),
                ButtonSegment(value: MovementType.ajuste, label: Text('Ajustes')),
              ],
              selected: {filter.type},
              onSelectionChanged: (value) => notifier.setType(value.first),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(context, from: true),
                    icon: const Icon(Icons.event, size: 18),
                    label: Text(
                      filter.from == null
                          ? 'Desde'
                          : Formatters.date(filter.from!),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.gap),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(context, from: false),
                    icon: const Icon(Icons.event_available, size: 18),
                    label: Text(
                      filter.to == null ? 'Hasta' : Formatters.date(filter.to!),
                    ),
                  ),
                ),
              ],
            ),
            if (!filter.isEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: notifier.clearFilters,
                  icon: const Icon(Icons.filter_alt_off, size: 18),
                  label: const Text('Limpiar filtros'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, {required bool from}) async {
    final initial = (from ? state.filter.from : state.filter.to) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    await notifier.setRange(
      from ? picked : state.filter.from,
      from ? state.filter.to : picked,
    );
  }
}
