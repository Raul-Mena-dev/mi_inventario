import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/data/database/ticket_repository.dart';
import 'package:inventario_app/data/models/expense.dart';
import 'package:inventario_app/data/models/product.dart';
import 'package:inventario_app/data/models/ticket.dart';
import 'package:inventario_app/data/models/ticket_item.dart';
import 'package:inventario_app/data/repositories/business_repository.dart';

import 'test_database.dart';

void main() {
  late TestDatabase testDatabase;

  setUp(() async {
    testDatabase = await TestDatabase.create();
  });

  tearDown(() async {
    await testDatabase.dispose();
  });

  test('summary combines sales, profit, expenses, and pending balances',
      () async {
    final product = Product(
      id: 1,
      name: 'Taza',
      description: '',
      price: 100,
      cost: 55,
      stock: 10,
      category: 'Hogar',
      subcategory: 'Cocina',
    );
    final item = TicketItem(product: product, quantity: 2);

    await TicketRepository.insertTicket(
      Ticket(
        date: DateTime.now().toIso8601String(),
        total: 200,
        pdfPath: '/tmp/ticket.pdf',
        paymentStatus: 'partial',
        paidAmount: 150,
        profit: 90,
      ),
      items: [item],
    );
    await BusinessRepository.insertExpense(
      Expense(
        concept: 'Empaques',
        amount: 20,
        category: 'Operación',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    final summary = await BusinessRepository.getSummary();
    final topProducts = await BusinessRepository.getTopProducts();
    final pendingTickets = await BusinessRepository.getPendingTickets();

    expect(summary.sales, 200);
    expect(summary.profit, 90);
    expect(summary.expenses, 20);
    expect(summary.netProfit, 70);
    expect(summary.pending, 50);
    expect(topProducts.first.productName, 'Taza');
    expect(topProducts.first.quantity, 2);
    expect(pendingTickets, hasLength(1));
  });
}
