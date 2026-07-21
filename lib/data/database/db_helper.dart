import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static const int _dbVersion = 3;
  static DatabaseFactory? _databaseFactory;
  static String? _databasePath;
  static Database? _testingDatabase;

  static void configureForTesting({
    required DatabaseFactory databaseFactory,
    required String databasePath,
  }) {
    _databaseFactory = databaseFactory;
    _databasePath = databasePath;
  }

  static void resetTestingConfig() {
    _databaseFactory = null;
    _databasePath = null;
    _testingDatabase = null;
  }

  static Future<void> closeTestingDatabase() async {
    await _testingDatabase?.close();
    _testingDatabase = null;
  }

  static Future<Database> initDB() async {
    final path =
        _databasePath ?? join(await getDatabasesPath(), 'inventory.db');

    if (_databaseFactory != null) {
      if (_testingDatabase != null) return _testingDatabase!;

      _testingDatabase = await _databaseFactory!.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _dbVersion,
          onCreate: _createTables,
          onUpgrade: _upgradeDatabase,
        ),
      );
      return _testingDatabase!;
    }

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            description TEXT,
            price REAL,
            stock INTEGER NOT NULL DEFAULT 0,
            category TEXT,
            subcategory TEXT,
            imagePath TEXT
          )
        ''');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS tickets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            total REAL,
            pdfPath TEXT
          )
        ''');
    await _createInventoryMovementsTable(db);
  }

  static Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE products ADD COLUMN stock INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await _createInventoryMovementsTable(db);
    }
  }

  static Future<void> _createInventoryMovementsTable(Database db) async {
    await db.execute('''
          CREATE TABLE IF NOT EXISTS inventory_movements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            productId INTEGER NOT NULL,
            productName TEXT NOT NULL,
            quantityChange INTEGER NOT NULL,
            stockAfter INTEGER NOT NULL,
            reason TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
  }
}
