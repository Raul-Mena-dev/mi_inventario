import 'dart:io';
import 'dart:convert';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/database/db_helper.dart';
import 'settings_service.dart';

class BackupService {
  static Future<File> createBackup() async {
    await DBHelper.closeDatabase();
    final sourcePath = await DBHelper.databasePath();
    final source = File(sourcePath);
    if (!await source.exists()) {
      await DBHelper.initDB();
      throw StateError('No se encontró la base de datos para respaldar');
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final backup =
        File(p.join(directory.path, 'respaldo_mi_inventario_$timestamp.zip'));

    final archive = Archive();
    archive.addFile(
      ArchiveFile(
        'inventory.db',
        await source.length(),
        await source.readAsBytes(),
      ),
    );

    final imageDir = Directory(p.join(directory.path, 'images'));
    if (await imageDir.exists()) {
      final files = imageDir.listSync(recursive: true).whereType<File>();
      for (final file in files) {
        final relativePath = p.relative(file.path, from: directory.path);
        archive.addFile(
          ArchiveFile(
            relativePath,
            await file.length(),
            await file.readAsBytes(),
          ),
        );
      }
    }

    final settings = await _settingsForBackup(directory.path);
    final settingsBytes = utf8.encode(jsonEncode(settings));
    archive.addFile(
      ArchiveFile('settings.json', settingsBytes.length, settingsBytes),
    );

    final encoded = ZipEncoder().encode(archive);
    await backup.writeAsBytes(encoded);
    await DBHelper.initDB();
    return backup;
  }

  static Future<void> shareBackup() async {
    final backup = await createBackup();
    await Share.shareXFiles(
      [XFile(backup.path)],
      text: 'Respaldo de Mi Inventario',
    );
  }

  static Future<void> restoreBackup(String backupPath) async {
    final backup = File(backupPath.trim());
    if (!await backup.exists()) {
      throw StateError('El archivo de respaldo no existe');
    }

    if (p.extension(backup.path).toLowerCase() == '.db') {
      await _restoreLegacyDatabase(backup);
      return;
    }

    final bytes = await backup.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final databaseFile = archive.findFile('inventory.db');
    if (databaseFile == null) {
      throw StateError('El respaldo no contiene la base de datos');
    }

    await DBHelper.closeDatabase();
    final targetPath = await DBHelper.databasePath();
    await File(targetPath).writeAsBytes(databaseFile.content as List<int>);

    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(p.join(appDir.path, 'images'));
    if (await imageDir.exists()) {
      await imageDir.delete(recursive: true);
    }
    await imageDir.create(recursive: true);

    for (final entry in archive.files) {
      if (!entry.isFile || !entry.name.startsWith('images/')) continue;
      final output = File(p.join(appDir.path, entry.name));
      await output.parent.create(recursive: true);
      await output.writeAsBytes(entry.content as List<int>);
    }

    await DBHelper.initDB();
    await _repairImagePaths(appDir.path);
    await _restoreSettings(archive, appDir.path);
  }

  static Future<void> _restoreLegacyDatabase(File backup) async {
    await DBHelper.closeDatabase();
    final targetPath = await DBHelper.databasePath();
    await backup.copy(targetPath);
    await DBHelper.initDB();
  }

  static Future<Map<String, dynamic>> _settingsForBackup(
      String appDirPath) async {
    final settings = await SettingsService.exportSettings();
    final logoPath = (settings["logoPath"] ?? "") as String;
    settings["logoFileName"] = logoPath.isEmpty || !File(logoPath).existsSync()
        ? ""
        : p.basename(logoPath);
    return settings;
  }

  static Future<void> _restoreSettings(
    Archive archive,
    String appDirPath,
  ) async {
    final settingsFile = archive.findFile('settings.json');
    if (settingsFile == null) return;

    final settings = jsonDecode(utf8.decode(settingsFile.content as List<int>));
    if (settings is! Map<String, dynamic>) return;

    final logoFileName = (settings["logoFileName"] ?? "") as String;
    if (logoFileName.isNotEmpty) {
      final logoPath = p.join(appDirPath, 'images', logoFileName);
      if (File(logoPath).existsSync()) {
        settings["logoPath"] = logoPath;
      }
    }
    await SettingsService.importSettings(settings);
  }

  static Future<void> _repairImagePaths(String appDirPath) async {
    final db = await DBHelper.initDB();
    final rows = await db.query('products', columns: ['id', 'imagePath']);
    for (final row in rows) {
      final id = row['id'];
      final imagePath = row['imagePath'] as String?;
      if (id == null || imagePath == null || imagePath.isEmpty) continue;

      final filename = p.basename(imagePath);
      final restoredPath = p.join(appDirPath, 'images', filename);
      if (File(restoredPath).existsSync() && restoredPath != imagePath) {
        await db.update(
          'products',
          {'imagePath': restoredPath},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }
  }
}
