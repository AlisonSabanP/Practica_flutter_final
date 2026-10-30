import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../../settings/presentation/providers/profile_providers.dart';
import '../../domain/entities/movement.dart';
import '../../domain/entities/movement_type.dart';
import '../../domain/repositories/inventory_repository.dart';

/// Historial de movimientos con filtros. Se usa en la pantalla de historial y
/// en el detalle del producto.
class MovementListNotifier extends Notifier<MovementListState> {
  @override
  MovementListState build() {
    Future.microtask(load);
    return const MovementListState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final movements = await ref.read(getMovementsProvider).call(
            filter: state.filter,
          );
      state = state.copyWith(
        movements: movements,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> setProduct(int? productId) async {
    state = state.copyWith(
      filter: productId == null
          ? state.filter.copyWith(clearProduct: true)
          : state.filter.copyWith(productId: productId),
    );
    await load();
  }

  Future<void> setType(MovementType? type) async {
    state = state.copyWith(
      filter: type == null
          ? state.filter.copyWith(clearType: true)
          : state.filter.copyWith(type: type),
    );
    await load();
  }

  Future<void> setRange(DateTime? from, DateTime? to) async {
    state = state.copyWith(
      filter: state.filter.copyWith(
        from: from,
        to: to,
        clearFrom: from == null,
        clearTo: to == null,
      ),
    );
    await load();
  }

  Future<void> clearFilters() async {
    state = state.copyWith(filter: const MovementFilter());
    await load();
  }
}

class MovementListState {
  const MovementListState({
    this.filter = const MovementFilter(),
    this.movements = const [],
    this.isLoading = true,
    this.error,
  });

  final MovementFilter filter;
  final List<Movement> movements;
  final bool isLoading;
  final String? error;

  MovementListState copyWith({
    MovementFilter? filter,
    List<Movement>? movements,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MovementListState(
      filter: filter ?? this.filter,
      movements: movements ?? this.movements,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final movementListProvider =
    NotifierProvider<MovementListNotifier, MovementListState>(MovementListNotifier.new);

/// Movimientos de un producto concreto, para el detalle del producto.
final productMovementsProvider =
    FutureProvider.family<List<Movement>, int>((ref, productId) {
  return ref.watch(getMovementsForProductProvider).call(productId);
});

/// Resumen del inventario para la pantalla de inicio.
final inventorySummaryProvider = FutureProvider((ref) {
  return ref.watch(getInventorySummaryProvider).call();
});

/// Productos con existencias iguales o inferiores al minimo.
final lowStockProductsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(getLowStockProductsProvider).call();
});

/// Ultimos movimientos registrados.
final recentMovementsProvider = FutureProvider<List<Movement>>((ref) {
  return ref.watch(getRecentMovementsProvider).call(limit: 6);
});

/// Registra un movimiento y refresca los proveedores afectados. Devuelve el
/// resultado para que la pantalla muestre la confirmacion.
final movementRegistrationProvider = Provider((ref) {
  return ({
    required Product product,
    required MovementType type,
    required int quantity,
    required String reason,
  }) async {
    final responsible = ref.read(getResponsibleNameProvider)();
    final result = await ref.read(registerMovementProvider).call(
          product: product,
          type: type,
          quantity: quantity,
          reason: reason,
          responsible: responsible,
        );
    _invalidateInventory(ref);
    return result;
  };
});

/// Funcion que devuelve el nombre del responsable configurado.
final getResponsibleNameProvider = Provider<String Function()>((ref) {
  return () {
    final profile = ref.read(profileProvider).value;
    return profile?.responsibleName ?? '';
  };
});

void _invalidateInventory(Ref ref) {
  ref.invalidate(inventorySummaryProvider);
  ref.invalidate(lowStockProductsProvider);
  ref.invalidate(recentMovementsProvider);
  ref.invalidate(movementListProvider);
  ref.invalidate(productListProvider);
}

/// Expuesto para que otras capas refresquen los datos de inventario.
void invalidateInventoryProviders(Ref ref) => _invalidateInventory(ref);

/// Reexporta el resultado del registro para la capa de presentacion.
typedef MovementRegistrationResult = MovementResult;
