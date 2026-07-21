import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/data/models/product.dart';
import 'package:inventario_app/data/models/ticket_item.dart';

void main() {
  test('Product.fromMap reads stock and normalizes missing values', () {
    final product = Product.fromMap({
      'id': 1,
      'name': 'Taza',
      'description': null,
      'price': 25,
      'stock': 8,
      'category': 'Hogar',
      'subcategory': 'Cocina',
      'imagePath': null,
    });

    expect(product.id, 1);
    expect(product.name, 'Taza');
    expect(product.description, '');
    expect(product.price, 25);
    expect(product.stock, 8);
  });

  test('TicketItem total uses quantity and product price', () {
    final product = Product(
      id: 1,
      name: 'Taza',
      description: '',
      price: 25,
      stock: 10,
      category: 'Hogar',
      subcategory: 'Cocina',
    );

    final item = TicketItem(product: product, quantity: 3);

    expect(item.total, 75);
  });
}
