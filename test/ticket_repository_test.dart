import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/data/database/ticket_repository.dart';
import 'package:inventario_app/data/models/ticket.dart';
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

  test('keeps only the five most recent tickets and deletes old PDFs',
      () async {
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

    expect(tickets, hasLength(5));
    expect(await files.first.exists(), isFalse);
    expect(await files.last.exists(), isTrue);
  });
}
