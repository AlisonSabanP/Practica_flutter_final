import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';
import '../../../inventory/presentation/screens/movement_screen.dart';
import '../../../inventory/presentation/widgets/movement_tile.dart';
import '../../../scanner/presentation/screens/scanner_screen.dart';
import '../../domain/entities/product.dart';
import '../providers/product_providers.dart';
import '../services/label_export_service.dart';
import '../widgets/product_label.dart';
import 'product_form_screen.dart';
import '../../../../core/di/providers.dart';

/// Detalle del producto: datos, existencias, etiquetas y movimientos.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final GlobalKey _labelKey = GlobalKey();
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(productDetailProvider(widget.productId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del producto'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () =>
                ref.invalidate(productDetailProvider(widget.productId)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const LoadingView(message: 'Cargando producto'),
        error: (error, _) => ErrorView(
          message: describeError(error),
          onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
        ),
        data: (product) => product == null
            ? const EmptyState(
                title: 'Producto no encontrado',
                message: 'El producto pudo haber sido eliminado.',
                icon: Icons.search_off,
              )
            : _buildDetail(context, product),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Product product) {
    final scheme = Theme.of(context).colorScheme;
    final movements = ref.watch(productMovementsProvider(widget.productId));

    return ListView(
      padding: AppTheme.screenPadding,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Photo(path: product.photoPath),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Codigo ${product.code}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        product.categoryName ?? 'Sin categoria',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          StatusChip(
                            label: 'Stock ${product.currentStock}',
                            color: product.isBelowMinimum
                                ? scheme.error
                                : scheme.primary,
                            icon: product.isBelowMinimum
                                ? Icons.warning_amber
                                : Icons.inventory_2_outlined,
                          ),
                          StatusChip(
                            label: 'Minimo ${product.minimumStock}',
                            color: scheme.outline,
                          ),
                          StatusChip(
                            label: product.active ? 'Activo' : 'Inactivo',
                            color: product.active ? scheme.primary : scheme.outline,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (product.isBelowMinimum)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.gap),
            child: Card(
              color: scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: scheme.onErrorContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Alerta: existencias iguales o inferiores al minimo (${product.minimumStock}).',
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: AppTheme.gap),
        Card(
          child: Column(
            children: [
              _DataRow(
                label: 'Precio de compra',
                value: Formatters.currency(product.purchasePrice),
              ),
              const Divider(height: 1),
              _DataRow(
                label: 'Precio de venta',
                value: Formatters.currency(product.salePrice),
              ),
              const Divider(height: 1),
              _DataRow(
                label: 'Valor en inventario',
                value: Formatters.currency(product.inventoryValue),
              ),
              if (product.description.isNotEmpty) ...[
                const Divider(height: 1),
                _DataRow(label: 'Descripcion', value: product.description),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppTheme.gap),
        const SectionHeader(title: 'Etiqueta de codigos'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                RepaintBoundary(
                  key: _labelKey,
                  child: ProductLabel(product: product),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _exporting ? null : () => _shareLabel(product),
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Compartir etiqueta'),
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
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.gap),
        const SectionHeader(title: 'Registrar movimiento'),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _openMovement(product),
                icon: const Icon(Icons.swap_vert),
                label: const Text('Movimiento'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.gap),
        const SectionHeader(title: 'Editar producto'),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _edit(product),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
            ),
            const SizedBox(width: AppTheme.gap),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _toggleActive(product),
                icon: Icon(
                  product.active ? Icons.block : Icons.check_circle_outline,
                ),
                label: Text(product.active ? 'Desactivar' : 'Activar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.gap),
        const SectionHeader(title: 'Ultimos movimientos'),
        movements.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: LoadingView(),
          ),
          error: (error, _) => ErrorView(message: describeError(error)),
          data: (items) => items.isEmpty
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Este producto no tiene movimientos registrados.'),
                  ),
                )
              : Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        MovementTile(movement: items[i]),
                        if (i < items.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _shareLabel(Product product) async {
    setState(() => _exporting = true);
    try {
      await ref.read(labelExportServiceProvider).shareLabel(
            boundaryKey: _labelKey,
            product: product,
          );
      _showMessage('Etiqueta lista para compartir o imprimir.');
    } catch (error) {
      _showMessage(describeError(error));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _openMovement(Product product) async {
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => MovementScreen(product: product),
      ),
    );
    if (registered == true) {
      ref.invalidate(productDetailProvider(widget.productId));
      ref.invalidate(productMovementsProvider(widget.productId));
    }
  }

  Future<void> _edit(Product product) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => ProductFormScreen(product: product)),
    );
    if (saved == true) {
      ref.invalidate(productDetailProvider(widget.productId));
      ref.invalidate(productListProvider);
    }
  }

  Future<void> _toggleActive(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.active ? 'Desactivar producto' : 'Activar producto'),
        content: Text(
          product.active
              ? 'El producto dejara de aparecer en el listado activo, pero conserva su historial.'
              : 'El producto volvera a estar disponible para registrar movimientos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(setProductActiveProvider).call(product.id!, !product.active);
      ref.invalidate(productDetailProvider(widget.productId));
      ref.invalidate(productListProvider);
      _showMessage(product.active ? 'Producto desactivado.' : 'Producto activado.');
    } catch (error) {
      _showMessage(describeError(error));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPhoto = path != null && File(path!).existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        height: 72,
        child: hasPhoto
            ? Image.file(File(path!), fit: BoxFit.cover)
            : Container(
                color: scheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: scheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}
