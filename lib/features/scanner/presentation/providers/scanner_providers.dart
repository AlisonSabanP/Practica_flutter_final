import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../inventory/domain/entities/movement.dart';
import '../../../products/domain/entities/product.dart';

/// Estado del permiso de camara.
enum ScannerPermission { checking, granted, denied, permanentlyDenied }

/// Resultado de una lectura: producto encontrado, codigo no registrado o error.
class ScannerState {
  const ScannerState({
    this.permission = ScannerPermission.granted,
    this.isSearching = false,
    this.product,
    this.movements = const [],
    this.notFoundCode,
    this.error,
  });

  final ScannerPermission permission;
  final bool isSearching;
  final Product? product;
  final List<Movement> movements;

  /// Codigo leido que no corresponde a ningun producto registrado.
  final String? notFoundCode;
  final String? error;

  ScannerState copyWith({
    ScannerPermission? permission,
    bool? isSearching,
    Product? product,
    List<Movement>? movements,
    String? notFoundCode,
    String? error,
    bool clearResult = false,
  }) {
    return ScannerState(
      permission: permission ?? this.permission,
      isSearching: isSearching ?? this.isSearching,
      product: clearResult ? null : (product ?? this.product),
      movements: clearResult ? const [] : (movements ?? this.movements),
      notFoundCode: clearResult ? null : (notFoundCode ?? this.notFoundCode),
      error: clearResult ? null : (error ?? this.error),
    );
  }
}

class ScannerNotifier extends Notifier<ScannerState> {
  @override
  ScannerState build() => const ScannerState();

  void setPermission(ScannerPermission permission) {
    state = state.copyWith(permission: permission);
  }

  void setError(String message) {
    state = state.copyWith(error: message);
  }

  void clear() {
    state = state.copyWith(clearResult: true);
  }

  /// Busca el producto por codigo unico. Si [searchByName] esta activo y no se
  /// encuentra por codigo, intenta por nombre.
  Future<void> lookup(String value, {bool searchByName = false}) async {
    state = state.copyWith(isSearching: true, clearResult: true);
    try {
      var product = await ref.read(getProductByCodeProvider).call(value);

      if (product == null && searchByName) {
        final matches = await ref.read(productRepositoryProvider).search(value);
        if (matches.length == 1) product = matches.first;
      }

      if (product == null) {
        state = state.copyWith(isSearching: false, notFoundCode: value);
        return;
      }

      final movements = await ref
          .read(getMovementsForProductProvider)
          .call(product.id!, limit: 5);

      state = state.copyWith(
        isSearching: false,
        product: product,
        movements: movements,
      );
    } catch (error) {
      state = state.copyWith(isSearching: false, error: error.toString());
    }
  }

  /// Recarga el producto y sus movimientos tras registrar un movimiento.
  Future<void> refreshCurrent() async {
    final current = state.product;
    if (current == null) return;
    await lookup(current.code);
  }
}

final scannerProvider = NotifierProvider<ScannerNotifier, ScannerState>(
  ScannerNotifier.new,
);
