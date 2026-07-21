import 'dart:io';

import 'package:inventario_app/data/database/db_helper.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TestDatabase {
  TestDatabase._(this.directory);

  final Directory directory;

  static Future<TestDatabase> create() async {
    sqfliteFfiInit();
    final directory = await Directory.systemTemp.createTemp('inventario_test_');
    DBHelper.configureForTesting(
      databaseFactory: databaseFactoryFfi,
      databasePath: p.join(directory.path, 'inventory_test.db'),
    );
    return TestDatabase._(directory);
  }

  Future<void> dispose() async {
    await DBHelper.closeTestingDatabase();
    DBHelper.resetTestingConfig();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
