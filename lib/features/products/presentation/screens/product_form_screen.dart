import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/product.dart';
import '../../domain/services/product_validator.dart';
import '../providers/product_providers.dart';
import '../../../inventory/presentation/providers/inventory_providers.dart';

/// Formulario de creacion y edicion de productos. Las validaciones provienen
/// del dominio; el formulario solo las presenta.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.product});

  /// Producto a editar. Si es nulo, el formulario crea uno nuevo.
  final Product? product;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _purchasePrice;
  late final TextEditingController _salePrice;
  late final TextEditingController _minimumStock;
  late final TextEditingController _initialStock;
  late final TextEditingController _newCategory;

  int? _categoryId;
  String? _photoPath;
  bool _saving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _code = TextEditingController(text: product?.code ?? '');
    _name = TextEditingController(text: product?.name ?? '');
    _description = TextEditingController(text: product?.description ?? '');
    _purchasePrice = TextEditingController(
      text: product == null ? '' : product.purchasePrice.toStringAsFixed(2),
    );
    _salePrice = TextEditingController(
      text: product == null ? '' : product.salePrice.toStringAsFixed(2),
    );
    _minimumStock = TextEditingController(
      text: product == null ? '5' : product.minimumStock.toString(),
    );
    _initialStock = TextEditingController();
    _newCategory = TextEditingController();
    _categoryId = product?.categoryId;
    _photoPath = product?.photoPath;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _description.dispose();
    _purchasePrice.dispose();
    _salePrice.dispose();
    _minimumStock.dispose();
    _initialStock.dispose();
    _newCategory.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar producto' : 'Nuevo producto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppTheme.screenPadding,
          children: [
            TextFormField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Codigo unico',
                helperText: 'Contenido del codigo de barras y del QR.',
              ),
              validator: ProductValidator.validateCode,
            ),
            const SizedBox(height: AppTheme.gap),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: ProductValidator.validateName,
            ),
            const SizedBox(height: AppTheme.gap),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripcion (opcional)',
              ),
              validator: ProductValidator.validateDescription,
            ),
            const SizedBox(height: AppTheme.gap),
            categories.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text(describeError(error)),
              data: (items) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int?>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Sin categoria'),
                      ),
                      for (final category in items)
                        DropdownMenuItem<int?>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newCategory,
                          decoration: const InputDecoration(
                            labelText: 'Crear categoria',
                            hintText: 'Nombre de la nueva categoria',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Agregar categoria',
                        onPressed: _createCategory,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.gap),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _purchasePrice,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Precio de compra',
                    ),
                    validator: (value) => ProductValidator.validatePrice(
                      value,
                      label: 'El precio de compra',
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.gap),
                Expanded(
                  child: TextFormField(
                    controller: _salePrice,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Precio de venta',
                    ),
                    validator: (value) => ProductValidator.validatePrice(
                      value,
                      label: 'El precio de venta',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.gap),
            TextFormField(
              controller: _minimumStock,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Stock minimo',
                helperText: 'Umbral para la alerta de existencias bajas.',
              ),
              validator: ProductValidator.validateMinimumStock,
            ),
            if (!_isEditing) ...[
              const SizedBox(height: AppTheme.gap),
              TextFormField(
                controller: _initialStock,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Stock inicial (opcional)',
                  helperText:
                      'Se registra como movimiento de entrada al guardar.',
                ),
                validator: ProductValidator.validateInitialStock,
              ),
            ],
            const SizedBox(height: AppTheme.gap),
            _PhotoPicker(
              path: _photoPath,
              onPick: _pickPhoto,
              onClear: () => setState(() => _photoPath = null),
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
                  : const Icon(Icons.save_outlined),
              label: Text(_isEditing ? 'Guardar cambios' : 'Crear producto'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createCategory() async {
    final name = _newCategory.text.trim();
    if (name.isEmpty) {
      _showMessage('Escribe el nombre de la categoria.');
      return;
    }
    try {
      final created = await ref
          .read(productRepositoryProvider)
          .createCategory(name);
      ref.invalidate(categoriesProvider);
      _newCategory.clear();
      setState(() => _categoryId = created.id);
      _showMessage('Categoria creada.');
    } catch (error) {
      _showMessage(describeError(error));
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (file == null) return;
      // La fotografia se copia al almacenamiento propio de la app
      // para que siga disponible aunque el archivo original se mueva.
      final directory = await getApplicationDocumentsDirectory();
      final target = File(
        p.join(
          directory.path,
          'fotos',
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}',
        ),
      );
      await target.parent.create(recursive: true);
      await File(file.path).copy(target.path);
      setState(() => _photoPath = target.path);
    } catch (error) {
      _showMessage(describeError(error));
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _saving = true);
    try {
      final purchase = _parseDecimal(_purchasePrice.text);
      final sale = _parseDecimal(_salePrice.text);
      final minimum = int.parse(_minimumStock.text.trim());
      final initial = _initialStock.text.trim().isEmpty
          ? 0
          : int.parse(_initialStock.text.trim());

      final profile = await ref.read(profileRepositoryProvider).load();

      final base = Product(
        id: widget.product?.id,
        code: _code.text.trim(),
        name: _name.text.trim(),
        description: _description.text.trim(),
        categoryId: _categoryId,
        purchasePrice: purchase,
        salePrice: sale,
        currentStock: widget.product?.currentStock ?? 0,
        minimumStock: minimum,
        photoPath: _photoPath,
        active: widget.product?.active ?? true,
      );

      if (_isEditing) {
        await ref.read(updateProductProvider).call(base);
      } else {
        await ref.read(createProductProvider).call(
              base,
              initialStock: initial,
              responsible: profile.responsibleName,
            );
      }

      ref.invalidate(productListProvider);
      ref.invalidate(inventorySummaryProvider);
      if (mounted) {
        Navigator.of(context).pop(true);
        _showMessage(
          _isEditing
              ? 'Producto actualizado.'
              : 'Producto creado${initial > 0 ? ' con entrada inicial de $initial unidades' : ''}.',
        );
      }
    } catch (error) {
      _showMessage(describeError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double _parseDecimal(String raw) =>
      double.parse(raw.trim().replaceAll(',', '.'));

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.path,
    required this.onPick,
    required this.onClear,
  });

  final String? path;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPhoto = path != null && File(path!).existsSync();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: hasPhoto
                    ? Image.file(File(path!), fit: BoxFit.cover)
                    : Container(
                        color: scheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.photo_camera_back_outlined,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fotografia (opcional)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasPhoto
                        ? 'Imagen seleccionada.'
                        : 'Sin imagen. Se usa un icono por defecto.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (hasPhoto)
              IconButton(
                tooltip: 'Quitar fotografia',
                onPressed: onClear,
                icon: const Icon(Icons.delete_outline),
              ),
            IconButton.filledTonal(
              tooltip: 'Seleccionar fotografia',
              onPressed: onPick,
              icon: const Icon(Icons.upload_file),
            ),
          ],
        ),
      ),
    );
  }
}
