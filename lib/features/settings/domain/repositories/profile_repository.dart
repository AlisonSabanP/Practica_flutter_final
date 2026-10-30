import '../entities/local_profile.dart';

abstract interface class ProfileRepository {
  Future<LocalProfile> load();

  Future<void> save(LocalProfile profile);
}
