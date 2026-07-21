import '../database/db_helper.dart';
import '../models/inventory_movement.dart';
import '../models/product.dart';
import '../models/ticket_item.dart';

class ProductRepository {
  static Future<int> insertProduct(Product product) async {
    final db = await DBHelper.initDB();
    final id = await db.insert('products', product.toMap());
    if (product.stock > 0) {
      await db.insert(
        'inventory_movements',
        InventoryMovement(
          productId: id,
          productName: product.name,
          quantityChange: product.stock,
          stockAfter: product.stock,
          reason: 'Alta de producto',
          createdAt: DateTime.now().toIso8601String(),
        ).toMap(),
      );
    }
    return id;
  }

  static Future<List<Product>> getProducts() async {
    final db = await DBHelper.initDB();
    final maps = await db.query('products');
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  static Future<int> deleteProduct(int id) async {
    final db = await DBHelper.initDB();
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> updateProduct(Product product) async {
    final db = await DBHelper.initDB();
    return db.transaction((txn) async {
      final previousRows = await txn.query(
        'products',
        columns: ['stock', 'name'],
        where: 'id = ?',
        whereArgs: [product.id],
        limit: 1,
      );
      final previousStock = previousRows.isEmpty
          ? product.stock
          : ((previousRows.first['stock'] as int?) ?? 0);

      final updated = await txn.update(
        'products',
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );

      final stockChange = product.stock - previousStock;
      final productId = product.id;
      if (productId != null && stockChange != 0) {
        await txn.insert(
          'inventory_movements',
          InventoryMovement(
            productId: productId,
            productName: product.name,
            quantityChange: stockChange,
            stockAfter: product.stock,
            reason: 'Ajuste manual',
            createdAt: DateTime.now().toIso8601String(),
          ).toMap(),
        );
      }

      return updated;
    });
  }

  static Future<void> decrementStock(List<TicketItem> items) async {
    final db = await DBHelper.initDB();
    await db.transaction((txn) async {
      for (final item in items) {
        final productId = item.product.id;
        if (productId == null) {
          throw StateError('Producto sin id: ${item.product.name}');
        }

        final rows = await txn.query(
          'products',
          columns: ['stock'],
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );

        if (rows.isEmpty) {
          throw StateError('Producto no encontrado: ${item.product.name}');
        }

        final currentStock = (rows.first['stock'] as int?) ?? 0;
        if (currentStock < item.quantity) {
          throw StateError(
            'Stock insuficiente para ${item.product.name}. Disponible: $currentStock',
          );
        }

        await txn.update(
          'products',
          {'stock': currentStock - item.quantity},
          where: 'id = ?',
          whereArgs: [productId],
        );
        await txn.insert(
          'inventory_movements',
          InventoryMovement(
            productId: productId,
            productName: item.product.name,
            quantityChange: -item.quantity,
            stockAfter: currentStock - item.quantity,
            reason: 'Venta',
            createdAt: DateTime.now().toIso8601String(),
          ).toMap(),
        );
      }
    });
  }

  static Future<List<Product>> getLowStockProducts({int threshold = 3}) async {
    final db = await DBHelper.initDB();
    final maps = await db.query(
      'products',
      where: 'stock <= ?',
      whereArgs: [threshold],
      orderBy: 'stock ASC, name COLLATE NOCASE ASC',
    );
    return maps.map(Product.fromMap).toList();
  }

  static Future<List<String>> validateStock(List<TicketItem> items) async {
    final db = await DBHelper.initDB();
    final errors = <String>[];

    for (final item in items) {
      final productId = item.product.id;
      if (productId == null) {
        errors.add('${item.product.name}: producto sin id');
        continue;
      }

      final rows = await db.query(
        'products',
        columns: ['stock'],
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );

      if (rows.isEmpty) {
        errors.add('${item.product.name}: producto no encontrado');
        continue;
      }

      final currentStock = (rows.first['stock'] as int?) ?? 0;
      if (currentStock < item.quantity) {
        errors.add(
          '${item.product.name}: disponible $currentStock, solicitado ${item.quantity}',
        );
      }
    }

    return errors;
  }

  static Future<List<String>> getCategories() async {
    final db = await DBHelper.initDB();
    final result = await db.rawQuery(
      '''
      SELECT DISTINCT category
      FROM products
      WHERE category IS NOT NULL AND category != ""
      ORDER BY category COLLATE NOCASE
      ''',
    );
    return result.map((row) => row['category'] as String).toList();
  }

  static Future<List<String>> getSubcategories(String category) async {
    final db = await DBHelper.initDB();
    final res = await db.rawQuery(
      '''
      SELECT DISTINCT subcategory
      FROM products
      WHERE category = ?
        AND subcategory IS NOT NULL
        AND subcategory != ''
      ORDER BY subcategory COLLATE NOCASE
      ''',
      [category],
    );
    return res.map((r) => r['subcategory'] as String).toList();
  }
}
