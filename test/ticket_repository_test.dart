import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/data/database/ticket_repository.dart';
import 'package:inventario_app/data/models/product.dart';
import 'package:inventario_app/data/models/ticket.dart';
import 'package:inventario_app/data/models/ticket_item.dart';
import 'package:path/path.dart' as p;

import 'test_database.dart';

void main() {
  late TestDatabase testDatabase;

  setUp(() async {
    testDatabase = await TestDatabase.create();
  });

  tearDown(() async {
    await testDatabase.dispose();
  });

  test('keeps full ticket history for business reports', () async {
    final files = <File>[];

    for (var i = 0; i < 6; i++) {
      final file = File(p.join(testDatabase.directory.path, 'ticket_$i.pdf'));
      await file.writeAsString('ticket $i');
      files.add(file);

      await TicketRepository.insertTicket(
        Ticket(
          date: '2026-05-23 10:0$i',
          total: i.toDouble(),
          pdfPath: file.path,
        ),
      );
    }

    final tickets = await TicketRepository.getTickets();

    expect(tickets, hasLength(6));
    expect(await files.first.exists(), isTrue);
    expect(await files.last.exists(), isTrue);
  });

  test('stores ticket items with profit snapshot', () async {
    final file = File(p.join(testDatabase.directory.path, 'ticket.pdf'));
    await file.writeAsString('ticket');

    final ticketId = await TicketRepository.insertTicket(
      Ticket(
        date: DateTime.now().toIso8601String(),
        total: 200,
        pdfPath: file.path,
        profit: 80,
      ),
      items: [
        TicketItem(
          product: Product(
            id: 1,
            name: 'Playera',
            description: '',
            price: 100,
            cost: 60,
            stock: 5,
            category: 'Ropa',
            subcategory: 'Playeras',
          ),
          quantity: 2,
        ),
      ],
    );

    final items = await TicketRepository.getTicketItems(ticketId);

    expect(items, hasLength(1));
    expect(items.first['productName'], 'Playera');
    expect(items.first['quantity'], 2);
    expect(items.first['profit'], 80);
  });

  test('addPayment updates pending ticket balance and stores payment history',
      () async {
    final ticketId = await TicketRepository.insertTicket(
      Ticket(
        date: DateTime.now().toIso8601String(),
        total: 300,
        pdfPath: '/tmp/ticket.pdf',
        paymentStatus: 'partial',
        paidAmount: 100,
      ),
    );
    final ticket = (await TicketRepository.getTickets())
        .firstWhere((item) => item.id == ticketId);

    await TicketRepository.addPayment(ticket, 200, note: 'Liquidación');

    final updated = (await TicketRepository.getTickets())
        .firstWhere((item) => item.id == ticketId);
    final payments = await TicketRepository.getPayments(ticketId);

    expect(updated.paymentStatus, 'paid');
    expect(updated.paidAmount, 300);
    expect(updated.pendingAmount, 0);
    expect(payments, hasLength(2));
    expect(payments.first.note, 'Liquidación');
  });
}
