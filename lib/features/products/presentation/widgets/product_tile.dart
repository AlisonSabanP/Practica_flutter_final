import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../domain/entities/product.dart';

/// Tarjeta de producto para los listados. Muestra codigo, categoria,
/// existencias y alerta cuando esta por debajo del minimo.
class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
    this.onTap,
    this.trailing,
  });

  final Product product;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final low = product.isBelowMinimum;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Thumbnail(product: product),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product.code} - ${product.categoryName ?? 'Sin categoria'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        StatusChip(
                          label: 'Stock ${product.currentStock}',
                          color: low ? scheme.error : scheme.primary,
                          icon: low
                              ? Icons.warning_amber
                              : Icons.inventory_2_outlined,
                        ),
                        StatusChip(
                          label: 'Min ${product.minimumStock}',
                          color: scheme.outline,
                        ),
                        if (!product.active)
                          StatusChip(
                            label: 'Inactivo',
                            color: scheme.outline,
                            icon: Icons.block,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  Text(
                    Formatters.currency(product.salePrice),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = product.photoPath;
    Widget child;
    if (path != null && File(path).existsSync()) {
      child = Image.file(
        File(path),
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(scheme),
      );
    } else {
      child = _placeholder(scheme);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: child,
    );
  }

  Widget _placeholder(ColorScheme scheme) {
    return Container(
      width: 54,
      height: 54,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.inventory_2_outlined,
        color: scheme.onSurfaceVariant,
        size: 22,
      ),
    );
  }
}
