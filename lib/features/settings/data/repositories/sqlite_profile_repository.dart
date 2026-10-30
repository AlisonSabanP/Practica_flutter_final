import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/local_profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// Persiste el perfil local en la tabla clave/valor `profile`.
class SqliteProfileRepository implements ProfileRepository {
  SqliteProfileRepository(this._appDatabase);

  final AppDatabase _appDatabase;

  static const String responsibleKey = 'responsible_name';
  static const String storeKey = 'store_name';

  @override
  Future<LocalProfile> load() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'profile',
      where: 'key IN (?, ?)',
      whereArgs: [responsibleKey, storeKey],
    );
    final values = {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
    final responsible = values[responsibleKey] ?? '';
    return LocalProfile(
      responsibleName: responsible,
      storeName: values[storeKey] ?? '',
      initialized: responsible.trim().isNotEmpty,
    );
  }

  @override
  Future<void> save(LocalProfile profile) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      await txn.insert(
        'profile',
        {'key': responsibleKey, 'value': profile.responsibleName},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.insert(
        'profile',
        {'key': storeKey, 'value': profile.storeName},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }
}
