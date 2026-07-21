import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static const int _dbVersion = 6;
  static DatabaseFactory? _databaseFactory;
  static String? _databasePath;
  static Database? _testingDatabase;
  static Database? _appDatabase;

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

  static Future<String> databasePath() async {
    return _databasePath ?? join(await getDatabasesPath(), 'inventory.db');
  }

  static Future<void> closeDatabase() async {
    await _testingDatabase?.close();
    _testingDatabase = null;
    await _appDatabase?.close();
    _appDatabase = null;
  }

  static Future<Database> initDB() async {
    final path = await databasePath();

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

    _appDatabase ??= await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
    return _appDatabase!;
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            description TEXT,
            price REAL,
            cost REAL NOT NULL DEFAULT 0,
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
            pdfPath TEXT,
            customerId INTEGER,
            customerName TEXT NOT NULL DEFAULT '',
            paymentStatus TEXT NOT NULL DEFAULT 'paid',
            paidAmount REAL NOT NULL DEFAULT 0,
            profit REAL NOT NULL DEFAULT 0
          )
        ''');
    await _createInventoryMovementsTable(db);
    await _createBusinessTables(db);
    await _createPaymentTables(db);
    await _createReminderTables(db);
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
    if (oldVersion < 4) {
      await _addColumnIfMissing(
        db,
        'products',
        'cost',
        'REAL NOT NULL DEFAULT 0',
      );
      await _addColumnIfMissing(db, 'tickets', 'customerId', 'INTEGER');
      await _addColumnIfMissing(
        db,
        'tickets',
        'customerName',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _addColumnIfMissing(
        db,
        'tickets',
        'paymentStatus',
        "TEXT NOT NULL DEFAULT 'paid'",
      );
      await _addColumnIfMissing(
        db,
        'tickets',
        'paidAmount',
        'REAL NOT NULL DEFAULT 0',
      );
      await _addColumnIfMissing(
        db,
        'tickets',
        'profit',
        'REAL NOT NULL DEFAULT 0',
      );
      await db.execute(
          'UPDATE tickets SET paidAmount = total WHERE paidAmount = 0');
      await _createBusinessTables(db);
    }
    if (oldVersion < 5) {
      await _createPaymentTables(db);
    }
    if (oldVersion < 6) {
      await _createReminderTables(db);
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

  static Future<void> _createBusinessTables(Database db) async {
    await db.execute('''
          CREATE TABLE IF NOT EXISTS customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL DEFAULT '',
            notes TEXT NOT NULL DEFAULT '',
            createdAt TEXT NOT NULL
          )
        ''');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            concept TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            notes TEXT NOT NULL DEFAULT ''
          )
        ''');
    await db.execute('''
          CREATE TABLE IF NOT EXISTS ticket_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ticketId INTEGER NOT NULL,
            productId INTEGER,
            productName TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            unitPrice REAL NOT NULL,
            unitCost REAL NOT NULL DEFAULT 0,
            total REAL NOT NULL,
            profit REAL NOT NULL DEFAULT 0
          )
        ''');
  }

  static Future<void> _createPaymentTables(Database db) async {
    await db.execute('''
          CREATE TABLE IF NOT EXISTS ticket_payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ticketId INTEGER NOT NULL,
            amount REAL NOT NULL,
            note TEXT NOT NULL DEFAULT '',
            createdAt TEXT NOT NULL
          )
        ''');
  }

  static Future<void> _createReminderTables(Database db) async {
    await db.execute('''
          CREATE TABLE IF NOT EXISTS reminders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            notes TEXT NOT NULL DEFAULT '',
            type TEXT NOT NULL DEFAULT 'other',
            scheduledAt TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            customerId INTEGER,
            customerName TEXT NOT NULL DEFAULT '',
            ticketId INTEGER,
            ticketLabel TEXT NOT NULL DEFAULT '',
            createdAt TEXT NOT NULL,
            completedAt TEXT
          )
        ''');
  }

  static Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }
}
