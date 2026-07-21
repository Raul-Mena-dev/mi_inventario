import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/data/models/product.dart';
import 'package:inventario_app/data/models/ticket_item.dart';
import 'package:inventario_app/data/repositories/inventory_movement_repository.dart';
import 'package:inventario_app/data/repositories/product_repository.dart';

import 'test_database.dart';

void main() {
  late TestDatabase testDatabase;

  setUp(() async {
    testDatabase = await TestDatabase.create();
  });

  tearDown(() async {
    await testDatabase.dispose();
  });

  test('inserts and reads products with stock', () async {
    await ProductRepository.insertProduct(
      Product(
        name: 'Playera',
        description: 'Algodon',
        price: 120,
        stock: 7,
        category: 'Ropa',
        subcategory: 'Playeras',
      ),
    );

    final products = await ProductRepository.getProducts();

    expect(products, hasLength(1));
    expect(products.first.name, 'Playera');
    expect(products.first.stock, 7);

    final movements = await InventoryMovementRepository.getMovements();
    expect(movements, hasLength(1));
    expect(movements.first.reason, 'Alta de producto');
    expect(movements.first.quantityChange, 7);
  });

  test('decrementStock reduces stock for ticket items', () async {
    final id = await ProductRepository.insertProduct(
      Product(
        name: 'Taza',
        description: '',
        price: 25,
        stock: 10,
        category: 'Hogar',
        subcategory: 'Cocina',
      ),
    );

    final product =
        (await ProductRepository.getProducts()).first.copyWith(id: id);
    await ProductRepository.decrementStock([
      TicketItem(product: product, quantity: 3),
    ]);

    final updated = await ProductRepository.getProducts();
    final movements = await InventoryMovementRepository.getMovements();

    expect(updated.first.stock, 7);
    expect(movements.first.reason, 'Venta');
    expect(movements.first.quantityChange, -3);
    expect(movements.first.stockAfter, 7);
  });

  test('validateStock returns an error when quantity exceeds stock', () async {
    final id = await ProductRepository.insertProduct(
      Product(
        name: 'Libreta',
        description: '',
        price: 40,
        stock: 2,
        category: 'Papeleria',
        subcategory: 'Libretas',
      ),
    );

    final product =
        (await ProductRepository.getProducts()).first.copyWith(id: id);
    final errors = await ProductRepository.validateStock([
      TicketItem(product: product, quantity: 4),
    ]);

    expect(errors, hasLength(1));
    expect(errors.first, contains('Libreta'));
    expect(errors.first, contains('disponible 2'));
  });

  test('updateProduct records manual stock adjustments', () async {
    final id = await ProductRepository.insertProduct(
      Product(
        name: 'Bolsa',
        description: '',
        price: 90,
        stock: 5,
        category: 'Accesorios',
        subcategory: 'Bolsas',
      ),
    );

    final product = (await ProductRepository.getProducts())
        .first
        .copyWith(id: id, stock: 8);

    await ProductRepository.updateProduct(product);

    final movements = await InventoryMovementRepository.getMovements();

    expect(movements.first.reason, 'Ajuste manual');
    expect(movements.first.quantityChange, 3);
    expect(movements.first.stockAfter, 8);
  });

  test('getLowStockProducts returns products at or below threshold', () async {
    await ProductRepository.insertProduct(
      Product(
        name: 'Cargador',
        description: '',
        price: 180,
        stock: 2,
        category: 'Electronica',
        subcategory: 'Accesorios',
      ),
    );
    await ProductRepository.insertProduct(
      Product(
        name: 'Audifonos',
        description: '',
        price: 300,
        stock: 6,
        category: 'Electronica',
        subcategory: 'Audio',
      ),
    );

    final products = await ProductRepository.getLowStockProducts(threshold: 3);

    expect(products, hasLength(1));
    expect(products.first.name, 'Cargador');
  });
}
