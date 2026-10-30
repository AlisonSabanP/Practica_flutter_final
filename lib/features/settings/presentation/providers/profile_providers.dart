import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/local_profile.dart';

/// Perfil local del dispositivo: nombre del responsable usado en cada
/// movimiento y nombre de la tienda.
class ProfileNotifier extends AsyncNotifier<LocalProfile> {
  @override
  Future<LocalProfile> build() => ref.watch(loadProfileProvider).call();

  Future<LocalProfile> save({
    required String responsibleName,
    required String storeName,
  }) async {
    final current = state.value ?? const LocalProfile();
    state = const AsyncLoading<LocalProfile>();
    try {
      final saved = await ref.read(saveProfileProvider).call(
            current.copyWith(
              responsibleName: responsibleName,
              storeName: storeName,
            ),
          );
      state = AsyncData(saved);
      return saved;
    } catch (error, stackTrace) {
      state = AsyncError<LocalProfile>(error, stackTrace);
      rethrow;
    }
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, LocalProfile>(ProfileNotifier.new);

/// Nombre del responsable activo, o cadena vacia si aun no se configura.
final responsibleNameProvider = Provider<String>((ref) {
  final profile = ref.watch(profileProvider).value;
  return profile?.responsibleName ?? '';
});
