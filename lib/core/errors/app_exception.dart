sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

class ValidationException extends AppException {
  const ValidationException(super.message, {this.field, super.cause});

  final String? field;
}

class DuplicateCodeException extends ValidationException {
  const DuplicateCodeException(String code, {super.cause})
      : super('El codigo "$code" ya esta registrado.', field: 'code');
}

class InsufficientStockException extends AppException {
  InsufficientStockException({
    required this.available,
    required this.requested,
    super.cause,
  }) : super(
          'No hay existencias suficientes: disponible $available, solicitado $requested.',
        );

  final int available;
  final int requested;
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause});
}

class ProductHasMovementsException extends AppException {
  const ProductHasMovementsException()
      : super(
          'El producto tiene movimientos registrados. Desactivalo en lugar de eliminarlo.',
        );
}

class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

class CameraException extends AppException {
  const CameraException(super.message, {super.cause});
}

String describeError(Object error) {
  if (error is AppException) return error.message;
  return 'Ocurrio un error inesperado: $error';
}
