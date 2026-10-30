import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_cards.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../inventory/domain/entities/movement.dart';
import '../../../inventory/presentation/screens/movement_screen.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/services/scan_code_normalizer.dart';
import '../providers/scanner_providers.dart';

/// Pantalla de lectura de codigos de barras y QR con la camara. Incluye
/// busqueda manual para cuando la camara no esta disponible.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final TextEditingController _manualCode = TextEditingController();
  late final MobileScannerController _controller;
  bool _handling = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    // La solicitud del permiso de camara la realiza el propio escaner al
    // iniciar. Si falla, el errorBuilder habilita la busqueda manual.
    Future.microtask(() {
      if (mounted) {
        ref
            .read(scannerProvider.notifier)
            .setPermission(ScannerPermission.granted);
      }
    });
  }

  @override
  void dispose() {
    _manualCode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scannerProvider);
    final notifier = ref.read(scannerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaner'),
        actions: [
          IconButton(
            tooltip: _torchOn ? 'Apagar linterna' : 'Encender linterna',
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
          ),
        ],
      ),
      body: ListView(
        padding: AppTheme.screenPadding,
        children: [
          _CameraArea(
            permission: state.permission,
            controller: _controller,
            onDetect: _onDetect,
            onRetryPermission: _retryCamera,
            onCameraError: _onCameraError,
          ),
          const SizedBox(height: AppTheme.gap),
          const SectionHeader(title: 'Busqueda manual'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  TextField(
                    controller: _manualCode,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      labelText: 'Codigo o nombre del producto',
                      prefixIcon: Icon(Icons.keyboard),
                    ),
                    onSubmitted: _onManualSearch,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _onManualSearch(_manualCode.text),
                          icon: const Icon(Icons.search),
                          label: const Text('Buscar'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.gap),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _manualCode.clear(),
                          icon: const Icon(Icons.clear),
                          label: const Text('Limpiar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.gap),
          if (state.isSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: LoadingView(message: 'Buscando producto'),
            )
          else if (state.error != null)
            ErrorView(message: state.error!, onRetry: () => notifier.clear())
          else if (state.notFoundCode != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Codigo no registrado: ${state.notFoundCode}. '
                        'Registra el producto para poder controlarlo.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (state.product != null)
            _ProductResult(
              product: state.product!,
              movements: state.movements,
              onRegisterMovement: () => _openMovement(state.product!),
              onOpenDetail: () => notifier.clear(),
            ),
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .firstWhere(
          (value) => value != null && value.isNotEmpty,
          orElse: () => null,
        );
    if (raw == null) return;

    final normalized = ScanCodeNormalizer.normalize(raw);
    if (!ScanCodeNormalizer.looksLikeProductCode(normalized)) return;

    _handling = true;
    await _lookup(normalized);
    // Pausa breve para evitar lecturas repetidas del mismo codigo.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    _handling = false;
  }

  Future<void> _onManualSearch(String value) async {
    final normalized = ScanCodeNormalizer.normalize(value);
    if (!ScanCodeNormalizer.looksLikeProductCode(normalized)) {
      ref
          .read(scannerProvider.notifier)
          .setError('Escribe un codigo o nombre valido para buscar.');
      return;
    }
    await _lookup(normalized, searchByName: true);
  }

  Future<void> _lookup(String value, {bool searchByName = false}) async {
    final notifier = ref.read(scannerProvider.notifier);
    await notifier.lookup(value, searchByName: searchByName);
    if (!mounted) return;
    final state = ref.read(scannerProvider);
    if (state.product != null) {
      _showMessage('Producto encontrado: ${state.product!.name}');
    } else if (state.notFoundCode != null) {
      _showMessage('Codigo no registrado: ${state.notFoundCode}');
    }
  }

  void _retryCamera() {
    final notifier = ref.read(scannerProvider.notifier);
    notifier.setPermission(ScannerPermission.granted);
    _controller.start();
  }

  void _onCameraError(MobileScannerException error) {
    if (!mounted) return;
    final permission =
        error.errorCode == MobileScannerErrorCode.permissionDenied
        ? ScannerPermission.permanentlyDenied
        : ScannerPermission.denied;
    ref.read(scannerProvider.notifier).setPermission(permission);
  }

  Future<void> _openMovement(Product product) async {
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => MovementScreen(product: product)),
    );
    if (registered == true) {
      await ref.read(scannerProvider.notifier).refreshCurrent();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CameraArea extends StatelessWidget {
  const _CameraArea({
    required this.permission,
    required this.controller,
    required this.onDetect,
    required this.onRetryPermission,
    required this.onCameraError,
  });

  final ScannerPermission permission;
  final MobileScannerController? controller;
  final void Function(BarcodeCapture) onDetect;
  final VoidCallback onRetryPermission;
  final void Function(MobileScannerException) onCameraError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (permission != ScannerPermission.granted || controller == null) {
      return Card(
        color: scheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(
                Icons.no_photography_outlined,
                size: 40,
                color: scheme.error,
              ),
              const SizedBox(height: 10),
              Text(
                permission == ScannerPermission.permanentlyDenied
                    ? 'Permiso de camara bloqueado'
                    : 'Camara no disponible',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                permission == ScannerPermission.permanentlyDenied
                    ? 'Habilita el permiso de camara en los ajustes del sistema para escanear codigos.'
                    : 'No se pudo iniciar la camara. Puedes usar la busqueda manual por codigo o nombre.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onRetryPermission,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: controller,
              onDetect: onDetect,
              errorBuilder: (context, error) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => onCameraError(error),
                );
                return ColoredBox(
                  color: scheme.surfaceContainerHigh,
                  child: const LoadingView(message: 'Iniciando camara'),
                );
              },
            ),
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 210,
                  height: 140,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: const Text(
                  'Apunta al codigo de barras o al QR',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductResult extends StatelessWidget {
  const _ProductResult({
    required this.product,
    required this.movements,
    required this.onRegisterMovement,
    required this.onOpenDetail,
  });

  final Product product;
  final List<Movement> movements;
  final VoidCallback onRegisterMovement;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Producto encontrado'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 10),
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
                      label: Formatters.currency(product.salePrice),
                      color: scheme.tertiary,
                    ),
                  ],
                ),
                if (product.isBelowMinimum) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Existencias iguales o inferiores al minimo.',
                    style: TextStyle(color: scheme.error),
                  ),
                ],
                if (!product.active) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Producto desactivado: no admite movimientos.',
                    style: TextStyle(color: scheme.error),
                  ),
                ],
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: product.active ? onRegisterMovement : null,
                  icon: const Icon(Icons.swap_vert),
                  label: const Text('Registrar movimiento'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onOpenDetail,
                  icon: const Icon(Icons.search),
                  label: const Text('Limpiar resultado'),
                ),
              ],
            ),
          ),
        ),
        if (movements.isNotEmpty) ...[
          const SizedBox(height: AppTheme.gap),
          const SectionHeader(title: 'Movimientos recientes'),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < movements.length; i++) ...[
                  ListTile(
                    dense: true,
                    leading: Icon(
                      movements[i].type.isIncrease
                          ? Icons.arrow_downward
                          : movements[i].type.isDecrease
                          ? Icons.arrow_upward
                          : Icons.tune,
                      color: scheme.onSurfaceVariant,
                    ),
                    title: Text(
                      '${movements[i].type.label} ${movements[i].quantity}',
                    ),
                    subtitle: Text(
                      '${Formatters.dateTime(movements[i].dateTime)} - ${movements[i].reason}',
                    ),
                  ),
                  if (i < movements.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
