import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_app/data/models/reminder.dart';
import 'package:inventario_app/data/repositories/reminder_repository.dart';

import 'test_database.dart';

void main() {
  late TestDatabase testDatabase;

  setUp(() async {
    testDatabase = await TestDatabase.create();
  });

  tearDown(() async {
    await testDatabase.dispose();
  });

  test('creates, completes, and deletes reminders', () async {
    final id = await ReminderRepository.insertReminder(
      Reminder(
        title: 'Cobrar pedido',
        type: 'collect',
        scheduledAt:
            DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
        customerId: 1,
        customerName: 'Cliente prueba',
        ticketId: 2,
        ticketLabel: 'Ticket 2 · \$250.00',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    final pending = await ReminderRepository.getPendingReminders();
    expect(pending, hasLength(1));
    expect(pending.first.id, id);
    expect(pending.first.customerName, 'Cliente prueba');

    await ReminderRepository.completeReminder(pending.first);
    expect(await ReminderRepository.getPendingReminders(), isEmpty);

    final all = await ReminderRepository.getReminders();
    expect(all.first.status, 'completed');

    await ReminderRepository.deleteReminder(id);
    expect(await ReminderRepository.getReminders(), isEmpty);
  });
}
