import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_schema.dart';

/// Acceso unico a la base de datos local sqflite. La aplicacion trabaja sin
/// conexion: toda la informacion vive en este archivo.
class AppDatabase {
  AppDatabase({this.directoryResolver});

  static final AppDatabase instance = AppDatabase();

  /// Permite inyectar el directorio de la base de datos en pruebas.
  final Future<String> Function()? directoryResolver;
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<String> _directoryPath() async {
    final resolver = directoryResolver;
    if (resolver != null) return resolver();
    return getDatabasesPath();
  }

  Future<Database> _open() async {
    final directory = await _directoryPath();
    final path = p.join(directory, DatabaseSchema.fileName);
    return openDatabase(
      path,
      version: DatabaseSchema.version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        final batch = db.batch();
        for (final statement in DatabaseSchema.createStatements) {
          batch.execute(statement);
        }
        await batch.commit(noResult: true);
      },
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// Elimina el archivo de base de datos. Se usa para reiniciar la aplicacion
  /// con los datos de demostracion.
  Future<void> deleteDatabaseFile() async {
    await close();
    final directory = await _directoryPath();
    final path = p.join(directory, DatabaseSchema.fileName);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
