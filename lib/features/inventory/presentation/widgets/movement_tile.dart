import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/movement.dart';

/// Fila de movimiento de inventario. Se usa en el inicio, el detalle del
/// producto y el historial.
class MovementTile extends StatelessWidget {
  const MovementTile({super.key, required this.movement, this.onTap});

  final Movement movement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEntry = movement.type.isIncrease;
    final isExit = movement.type.isDecrease;
    final color = isEntry
        ? scheme.primary
        : isExit
            ? scheme.error
            : scheme.tertiary;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.14),
        child: Icon(
          isEntry
              ? Icons.arrow_downward
              : isExit
                  ? Icons.arrow_upward
                  : Icons.tune,
          color: color,
          size: 20,
        ),
      ),
      title: Text(movement.productName ?? 'Producto ${movement.productId}'),
      subtitle: Text(
        '${movement.type.label} - ${movement.reason.isEmpty ? 'Sin motivo' : movement.reason}\n'
        '${Formatters.dateTime(movement.dateTime)} - ${movement.responsible}',
      ),
      isThreeLine: true,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            movement.type.isAbsolute
                ? '${movement.resultingStock}'
                : Formatters.signedQuantity(movement.delta),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            'stock ${movement.resultingStock}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
