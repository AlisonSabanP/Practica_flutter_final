import '../../../../core/errors/app_exception.dart';
import '../entities/product.dart';

/// Reglas de validacion de productos. Viven en el dominio y no dependen de
/// widgets ni del almacenamiento.
abstract final class ProductValidator {
  static const int codeMaxLength = 40;
  static const int nameMaxLength = 120;
  static const int descriptionMaxLength = 500;

  static String? validateCode(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'El codigo es obligatorio.';
    if (value.length > codeMaxLength) {
      return 'El codigo no puede superar $codeMaxLength caracteres.';
    }
    if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(value)) {
      return 'Usa solo letras, numeros, punto, guion o guion bajo.';
    }
    return null;
  }

  static String? validateName(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'El nombre es obligatorio.';
    if (value.length > nameMaxLength) {
      return 'El nombre no puede superar $nameMaxLength caracteres.';
    }
    return null;
  }

  static String? validateDescription(String? raw) {
    final value = (raw ?? '').trim();
    if (value.length > descriptionMaxLength) {
      return 'La descripcion no puede superar $descriptionMaxLength caracteres.';
    }
    return null;
  }

  static String? validatePrice(String? raw, {required String label}) {
    final value = (raw ?? '').trim().replaceAll(',', '.');
    if (value.isEmpty) return '$label es obligatorio.';
    final parsed = double.tryParse(value);
    if (parsed == null) return '$label debe ser un numero valido.';
    if (parsed <= 0) return '$label debe ser mayor que cero.';
    if (parsed > 100000000) return '$label excede el maximo permitido.';
    return null;
  }

  static String? validateMinimumStock(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'El stock minimo es obligatorio.';
    final parsed = int.tryParse(value);
    if (parsed == null) return 'El stock minimo debe ser un numero entero.';
    if (parsed < 0) return 'El stock minimo no puede ser negativo.';
    return null;
  }

  static String? validateInitialStock(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    final parsed = int.tryParse(value);
    if (parsed == null) return 'El stock inicial debe ser un numero entero.';
    if (parsed < 0) return 'El stock inicial no puede ser negativo.';
    return null;
  }

  static String? validateCategory(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'La categoria es obligatoria.';
    return null;
  }

  /// Valida la entidad completa antes de persistirla. Lanza
  /// [ValidationException] con el primer error encontrado.
  static void assertValid(Product product) {
    final errors = <String?>[
      validateCode(product.code),
      validateName(product.name),
      validateDescription(product.description),
      validatePrice(product.purchasePrice.toString(), label: 'El precio de compra'),
      validatePrice(product.salePrice.toString(), label: 'El precio de venta'),
      validateMinimumStock(product.minimumStock.toString()),
    ];
    for (final error in errors) {
      if (error != null) throw ValidationException(error);
    }
    if (product.salePrice < product.purchasePrice) {
      throw const ValidationException(
        'El precio de venta no puede ser menor que el precio de compra.',
        field: 'salePrice',
      );
    }
  }
}
