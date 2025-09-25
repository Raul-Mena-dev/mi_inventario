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

    static Future<int> updateProduct(Product product) async {
      final db = await DBHelper.initDB();
      return await db.update(
        'products',
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );
    }

  static Future<List<String>> getCategories() async {
    final db = await DBHelper.initDB();
    final result = await db.rawQuery('SELECT DISTINCT category FROM products WHERE category IS NOT NULL AND category != ""');
    return result.map((row) => row['category'] as String).toList();
  }


}
