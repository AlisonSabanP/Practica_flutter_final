import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../features/inventory/data/repositories/sqlite_inventory_repository.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/inventory/domain/usecases/register_movement.dart';
import '../../features/products/data/repositories/sqlite_product_repository.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/domain/usecases/product_usecases.dart';
import '../../features/reports/data/file_sharing_service.dart';
import '../../features/reports/domain/usecases/report_usecases.dart';
import '../../features/settings/data/repositories/sqlite_profile_repository.dart';
import '../../features/settings/domain/repositories/profile_repository.dart';
import '../../features/settings/domain/usecases/profile_usecases.dart';

/// Composicion de dependencias. Un unico punto de union entre el dominio y la
/// capa de datos, sin mezclar enfoques de gestion de estado.
final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => SqliteProductRepository(ref.watch(databaseProvider)),
);

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => SqliteInventoryRepository(ref.watch(databaseProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => SqliteProfileRepository(ref.watch(databaseProvider)),
);

final fileSharingServiceProvider =
    Provider<FileSharingService>((ref) => const FileSharingService());

// --- Casos de uso de productos ---

final getProductsProvider = Provider<GetProducts>(
  (ref) => GetProducts(ref.watch(productRepositoryProvider)),
);

final getProductByIdProvider = Provider<GetProductById>(
  (ref) => GetProductById(ref.watch(productRepositoryProvider)),
);

final getProductByCodeProvider = Provider<GetProductByCode>(
  (ref) => GetProductByCode(ref.watch(productRepositoryProvider)),
);

final createProductProvider = Provider<CreateProduct>(
  (ref) => CreateProduct(ref.watch(productRepositoryProvider)),
);

final updateProductProvider = Provider<UpdateProduct>(
  (ref) => UpdateProduct(ref.watch(productRepositoryProvider)),
);

final setProductActiveProvider = Provider<SetProductActive>(
  (ref) => SetProductActive(ref.watch(productRepositoryProvider)),
);

final deleteProductProvider = Provider<DeleteProduct>(
  (ref) => DeleteProduct(ref.watch(productRepositoryProvider)),
);

// --- Casos de uso de inventario ---

final registerMovementProvider = Provider<RegisterMovement>(
  (ref) => RegisterMovement(ref.watch(inventoryRepositoryProvider)),
);

final getMovementsProvider = Provider<GetMovements>(
  (ref) => GetMovements(ref.watch(inventoryRepositoryProvider)),
);

final getMovementsForProductProvider = Provider<GetMovementsForProduct>(
  (ref) => GetMovementsForProduct(ref.watch(inventoryRepositoryProvider)),
);

final getRecentMovementsProvider = Provider<GetRecentMovements>(
  (ref) => GetRecentMovements(ref.watch(inventoryRepositoryProvider)),
);

// --- Casos de uso de reportes ---

final getInventorySummaryProvider = Provider<GetInventorySummary>(
  (ref) => GetInventorySummary(ref.watch(productRepositoryProvider)),
);

final getInventoryProductsProvider = Provider<GetInventoryProducts>(
  (ref) => GetInventoryProducts(ref.watch(productRepositoryProvider)),
);

final getLowStockProductsProvider = Provider<GetLowStockProducts>(
  (ref) => GetLowStockProducts(ref.watch(productRepositoryProvider)),
);

// --- Casos de uso de perfil ---

final loadProfileProvider = Provider<LoadProfile>(
  (ref) => LoadProfile(ref.watch(profileRepositoryProvider)),
);

final saveProfileProvider = Provider<SaveProfile>(
  (ref) => SaveProfile(ref.watch(profileRepositoryProvider)),
);
