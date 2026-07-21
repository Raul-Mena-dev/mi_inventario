import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  static Future<String?> saveImageToAppStorage(String? sourcePath) async {
    if (sourcePath == null || sourcePath.trim().isEmpty) return null;

    final source = File(sourcePath);
    if (!await source.exists()) return sourcePath;

    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(p.join(appDir.path, 'images'));
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    if (p.isWithin(imageDir.path, source.path)) {
      return source.path;
    }

    final extension = p.extension(source.path);
    final safeExtension = extension.isEmpty ? '.jpg' : extension;
    final filename = '${DateTime.now().microsecondsSinceEpoch}$safeExtension';
    final destination = File(p.join(imageDir.path, filename));
    await source.copy(destination.path);
    return destination.path;
  }
}
