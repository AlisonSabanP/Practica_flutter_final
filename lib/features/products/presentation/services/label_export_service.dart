import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/product.dart';
import 'package:flutter/widgets.dart';

/// Genera la imagen PNG de la etiqueta y la comparte para impresion.
class LabelExportService {
  const LabelExportService(this._ref);

  final Ref _ref;

  Future<void> shareLabel({
    required GlobalKey boundaryKey,
    required Product product,
    double pixelRatio = 3,
  }) async {
    final bytes = await renderBoundaryToPng(
      boundaryKey: boundaryKey,
      pixelRatio: pixelRatio,
    );
    final file = await _ref.read(fileSharingServiceProvider).writeTemporaryBytes(
          fileName: 'etiqueta_${product.code}.png',
          bytes: bytes,
        );
    await _ref.read(fileSharingServiceProvider).shareFile(
          file,
          subject: 'Etiqueta ${product.name}',
          text: 'Etiqueta de ${product.name} (${product.code}).',
        );
  }

  /// Renderiza el widget marcado con [boundaryKey] a PNG.
  Future<Uint8List> renderBoundaryToPng({
    required GlobalKey boundaryKey,
    required double pixelRatio,
  }) async {
    final context = boundaryKey.currentContext;
    if (context == null) {
      throw const StorageException('La etiqueta aun no esta lista para exportar.');
    }
    final boundary = context.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw const StorageException('No se pudo capturar la etiqueta.');
    }
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw const StorageException('No se pudo generar la imagen de la etiqueta.');
    }
    return data.buffer.asUint8List();
  }
}

final labelExportServiceProvider =
    Provider<LabelExportService>((ref) => LabelExportService(ref));
