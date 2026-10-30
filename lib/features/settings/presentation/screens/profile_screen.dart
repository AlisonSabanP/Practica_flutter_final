import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/state_views.dart';
import '../providers/profile_providers.dart';

/// Perfil local: nombre del responsable usado en cada movimiento y nombre de
/// la tienda o bodega.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _responsible = TextEditingController();
  final _store = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _responsible.dispose();
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil local')),
      body: profile.when(
        loading: () => const LoadingView(message: 'Cargando perfil'),
        error: (error, _) => ErrorView(
          message: describeError(error),
          onRetry: () => ref.invalidate(profileProvider),
        ),
        data: (data) {
          if (!_initialized) {
            _responsible.text = data.responsibleName;
            _store.text = data.storeName;
            _initialized = true;
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: AppTheme.screenPadding,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.offline_bolt_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'La aplicacion funciona sin conexion. Todos los datos se guardan en este dispositivo.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.gap),
                TextFormField(
                  controller: _responsible,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del responsable',
                    helperText: 'Se guarda en cada movimiento de inventario.',
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return 'El nombre del responsable es obligatorio.';
                    if (text.length > 80) return 'Maximo 80 caracteres.';
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.gap),
                TextFormField(
                  controller: _store,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la tienda o bodega (opcional)',
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length > 80) {
                      return 'Maximo 80 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Guardar perfil'),
                ),
                const SizedBox(height: AppTheme.gap),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acerca de',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        const Text('INVENTARIO - version 1.0.0'),
                        const SizedBox(height: 4),
                        Text(
                          'Gestion de inventario sin conexion para una tienda y una bodega.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _saving = true);
    try {
      await ref.read(profileProvider.notifier).save(
            responsibleName: _responsible.text.trim(),
            storeName: _store.text.trim(),
          );
      _showMessage('Perfil guardado.');
    } on ValidationException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage(describeError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
