import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../products/domain/entities/product.dart';
import '../../../settings/presentation/providers/profile_providers.dart';
import '../../domain/entities/movement.dart';
import '../../domain/entities/movement_type.dart';
import '../../domain/services/stock_calculator.dart';
import '../providers/inventory_providers.dart';
import '../../domain/repositories/inventory_repository.dart';

/// Registro de entrada, salida y ajuste de existencias. La validacion final
/// la realiza el dominio; aqui se anticipa para dar mensajes inmediatos.
class MovementScreen extends ConsumerStatefulWidget {
  const MovementScreen({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends ConsumerState<MovementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _reason = TextEditingController();

  MovementType _type = MovementType.entrada;
  bool _saving = false;

  @override
  void dispose() {
    _quantity.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final product = widget.product;
    final responsible = ref.watch(responsibleNameProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Movimiento de inventario')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppTheme.screenPadding,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Codigo ${product.code}',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 10),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          'Stock actual: ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '${product.currentStock}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '/ minimo ${product.minimumStock}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.gap),
            SegmentedButton<MovementType>(
              segments: const [
                ButtonSegment(
                  value: MovementType.entrada,
                  label: Text('Entrada'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: MovementType.salida,
                  label: Text('Salida'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: MovementType.ajuste,
                  label: Text('Ajuste'),
                  icon: Icon(Icons.tune),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) {
                setState(() {
                  _type = value.first;
                  _reason.clear();
                  _quantity.clear();
                });
              },
            ),
            const SizedBox(height: AppTheme.gap),
            Text(
              _type.isAbsolute
                  ? 'Cantidad contada (stock final tras el conteo fisico)'
                  : 'Cantidad',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: _type.isAbsolute ? 'Stock contado' : 'Cantidad',
                helperText: _type.isAbsolute
                    ? 'El stock quedara con este valor.'
                    : null,
              ),
              validator: _validateQuantity,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppTheme.gap),
            Text(
              _type == MovementType.ajuste ? 'Justificacion' : 'Motivo',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _reason,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: _type == MovementType.ajuste ? 'Justificacion' : 'Motivo',
                hintText: _type == MovementType.ajuste
                    ? 'Describe el conteo o la correccion aplicada'
                    : 'Describe el motivo del movimiento',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return _type == MovementType.ajuste
                      ? 'El ajuste exige una justificacion.'
                      : 'El motivo es obligatorio.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final reason in MovementReasons.forType(_type))
                  ActionChip(
                    label: Text(reason),
                    onPressed: () {
                      _reason.text = reason;
                      setState(() {});
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.gap),
            _Preview(
              product: product,
              type: _type,
              quantity: int.tryParse(_quantity.text.trim()),
            ),
            const SizedBox(height: AppTheme.gap),
            Card(
              color: scheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        responsible.isEmpty
                            ? 'Sin responsable configurado. Configuralo en Perfil.'
                            : 'Responsable: $responsible',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text('Registrar ${_type.label.toLowerCase()}'),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateQuantity(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) {
      return _type.isAbsolute
          ? 'Indica el stock contado.'
          : 'La cantidad es obligatoria.';
    }
    final parsed = int.tryParse(value);
    if (parsed == null) return 'Usa un numero entero.';
    if (parsed < 0) return 'La cantidad no puede ser negativa.';
    if (!_type.isAbsolute && parsed == 0) {
      return 'La cantidad debe ser mayor que cero.';
    }
    if (_type.isDecrease && parsed > widget.product.currentStock) {
      return 'No puedes retirar mas de ${widget.product.currentStock} unidades.';
    }
    return null;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _saving = true);
    try {
      final quantity = int.parse(_quantity.text.trim());
      final result = await ref.read(movementRegistrationProvider)(
        product: widget.product,
        type: _type,
        quantity: quantity,
        reason: _reason.text.trim(),
      );
      if (!mounted) return;
      await _showSuccess(result);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      _showError(describeError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showSuccess(MovementResult result) {
    final product = result.product;
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Movimiento registrado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${result.movement.type.label} de ${result.movement.quantity} unidades.'),
            const SizedBox(height: 8),
            Text(
              'Stock anterior: ${result.movement.previousStock}\n'
              'Stock resultante: ${product.currentStock}',
            ),
            if (product.isBelowMinimum) ...[
              const SizedBox(height: 10),
              Text(
                'Alerta: el stock quedo igual o por debajo del minimo (${product.minimumStock}).',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
  }
}

/// Previsualizacion del stock resultante usando las mismas reglas del dominio.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.product,
    required this.type,
    required this.quantity,
  });

  final Product product;
  final MovementType type;
  final int? quantity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (quantity == null) {
      return const SizedBox.shrink();
    }

    String? error;
    int? resulting;
    try {
      final calculation = StockCalculator.apply(
        type: type,
        previousStock: product.currentStock,
        quantity: quantity!,
        reason: 'previsualizacion',
      );
      resulting = calculation.resultingStock;
    } on AppException catch (exception) {
      error = exception.message;
    }

    return Card(
      color: error != null ? scheme.errorContainer : scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              error != null ? Icons.error_outline : Icons.calculate_outlined,
              color: error != null ? scheme.onErrorContainer : scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error ?? 'Stock resultante: $resulting unidades',
                style: TextStyle(
                  color: error != null
                      ? scheme.onErrorContainer
                      : scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
