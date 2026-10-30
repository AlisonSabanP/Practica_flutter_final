import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../inventory/domain/entities/movement.dart';
import '../../products/domain/entities/product.dart';
import '../domain/services/inventory_csv_builder.dart';

/// Servicio de exportacion de reportes. Construye el CSV en el dominio y lo
/// comparte como archivo.
class ReportExportService {
  const ReportExportService(this._ref);

  final Ref _ref;

  Future<void> exportInventory(List<Product> products) async {
    final contents = InventoryCsvBuilder.buildInventory(products);
    final file = await _ref.read(fileSharingServiceProvider).writeTemporaryText(
          fileName: InventoryCsvBuilder.inventoryFileName(DateTime.now()),
          contents: contents,
        );
    await _ref.read(fileSharingServiceProvider).shareFile(
          file,
          subject: 'Inventario exportado',
          text: 'Exportacion del inventario en formato CSV.',
        );
  }

  Future<void> exportMovements(List<Movement> movements) async {
    final contents = InventoryCsvBuilder.buildMovements(movements);
    final file = await _ref.read(fileSharingServiceProvider).writeTemporaryText(
          fileName: InventoryCsvBuilder.movementsFileName(DateTime.now()),
          contents: contents,
        );
    await _ref.read(fileSharingServiceProvider).shareFile(
          file,
          subject: 'Historial de movimientos',
          text: 'Exportacion del historial de movimientos en formato CSV.',
        );
  }
}

final reportExportServiceProvider =
    Provider<ReportExportService>((ref) => ReportExportService(ref));
