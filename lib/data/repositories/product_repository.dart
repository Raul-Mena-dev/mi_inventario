import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import '../database/db_helper.dart';

class ProductRepository {
  static Future<int> insertProduct(Product product) async {
    final db = await DBHelper.initDB();
    return await db.insert('products', product.toMap());
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
}
