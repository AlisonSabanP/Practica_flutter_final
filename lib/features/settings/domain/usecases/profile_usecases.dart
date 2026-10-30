import '../../../../core/errors/app_exception.dart';
import '../entities/local_profile.dart';
import '../repositories/profile_repository.dart';

class LoadProfile {
  const LoadProfile(this._repository);

  final ProfileRepository _repository;

  Future<LocalProfile> call() => _repository.load();
}

class SaveProfile {
  const SaveProfile(this._repository);

  final ProfileRepository _repository;

  Future<LocalProfile> call(LocalProfile profile) async {
    final name = profile.responsibleName.trim();
    if (name.isEmpty) {
      throw const ValidationException(
        'El nombre del responsable es obligatorio.',
        field: 'responsibleName',
      );
    }
    if (name.length > 80) {
      throw const ValidationException(
        'El nombre del responsable no puede superar 80 caracteres.',
        field: 'responsibleName',
      );
    }
    final store = profile.storeName.trim();
    if (store.length > 80) {
      throw const ValidationException(
        'El nombre de la tienda no puede superar 80 caracteres.',
        field: 'storeName',
      );
    }
    final normalized = profile.copyWith(
      responsibleName: name,
      storeName: store,
      initialized: true,
    );
    await _repository.save(normalized);
    return normalized;
  }
}
