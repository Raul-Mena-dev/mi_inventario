import '../database/db_helper.dart';
import '../models/inventory_movement.dart';

class InventoryMovementRepository {
  static Future<int> insertMovement(InventoryMovement movement) async {
    final db = await DBHelper.initDB();
    return db.insert('inventory_movements', movement.toMap());
  }

  static Future<List<InventoryMovement>> getMovements({int limit = 100}) async {
    final db = await DBHelper.initDB();
    final maps = await db.query(
      'inventory_movements',
      orderBy: 'id DESC',
      limit: limit,
    );
    return maps.map(InventoryMovement.fromMap).toList();
  }

  static Future<List<InventoryMovement>> getMovementsForProduct(
    int productId, {
    int limit = 50,
  }) async {
    final db = await DBHelper.initDB();
    final maps = await db.query(
      'inventory_movements',
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'id DESC',
      limit: limit,
    );
    return maps.map(InventoryMovement.fromMap).toList();
  }
}
