import '../database/db_helper.dart';
import '../models/reminder.dart';

class ReminderRepository {
  static Future<int> insertReminder(Reminder reminder) async {
    final db = await DBHelper.initDB();
    return db.insert('reminders', reminder.toMap());
  }

  static Future<List<Reminder>> getReminders(
      {bool includeCompleted = true}) async {
    final db = await DBHelper.initDB();
    final rows = await db.query(
      'reminders',
      where: includeCompleted ? null : 'status = ?',
      whereArgs: includeCompleted ? null : ['pending'],
      orderBy: 'scheduledAt ASC',
    );
    return rows.map(Reminder.fromMap).toList();
  }

  static Future<List<Reminder>> getPendingReminders() {
    return getReminders(includeCompleted: false);
  }

  static Future<int> updateReminder(Reminder reminder) async {
    final db = await DBHelper.initDB();
    return db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  static Future<int> completeReminder(Reminder reminder) async {
    final db = await DBHelper.initDB();
    return db.update(
      'reminders',
      {
        'status': 'completed',
        'completedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  static Future<int> deleteReminder(int id) async {
    final db = await DBHelper.initDB();
    return db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }
}
