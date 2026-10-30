import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/app_exception.dart';

/// Escribe archivos temporales y los comparte con otras aplicaciones. Se usa
/// para exportar CSV y para compartir las etiquetas de codigos.
class FileSharingService {
  const FileSharingService();

  Future<File> writeTemporaryText({
    required String fileName,
    required String contents,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final target = Directory(p.join(directory.path, 'exports'));
      if (!await target.exists()) {
        await target.create(recursive: true);
      }
      final file = File(p.join(target.path, fileName));
      await file.writeAsString(contents);
      return file;
    } on FileSystemException catch (error) {
      throw StorageException(
        'No se pudo escribir el archivo en el almacenamiento del dispositivo.',
        cause: error,
      );
    }
  }

  Future<File> writeTemporaryBytes({
    required String fileName,
    required List<int> bytes,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final target = Directory(p.join(directory.path, 'exports'));
      if (!await target.exists()) {
        await target.create(recursive: true);
      }
      final file = File(p.join(target.path, fileName));
      await file.writeAsBytes(bytes);
      return file;
    } on FileSystemException catch (error) {
      throw StorageException(
        'No se pudo escribir el archivo en el almacenamiento del dispositivo.',
        cause: error,
      );
    }
  }

  Future<void> shareFile(File file, {required String subject, String? text}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: subject, text: text),
      );
    } catch (error) {
      throw StorageException(
        'No se pudo abrir el menu de compartir del dispositivo.',
        cause: error,
      );
    }
  }

  Future<void> shareText({required String subject, required String text}) async {
    try {
      await SharePlus.instance.share(ShareParams(subject: subject, text: text));
    } catch (error) {
      throw StorageException(
        'No se pudo abrir el menu de compartir del dispositivo.',
        cause: error,
      );
    }
  }
}
