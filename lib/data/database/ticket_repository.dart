import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/ticket.dart';

class TicketRepository {
  static Future<int> insertTicket(Ticket ticket) async {
    final db = await DBHelper.initDB();
    final id = await db.insert('tickets', ticket.toMap());
    await _limitToFive(db);
    return id;
  }

  static Future<void> _limitToFive(Database db) async {
    final tickets = await db.query('tickets', orderBy: 'id DESC');
    if (tickets.length > 5) {
      final toDelete = tickets.skip(5).map((t) => t['id']).toList();
      for (var id in toDelete) {
        await db.delete('tickets', where: 'id = ?', whereArgs: [id]);
      }
    }
  }

  static Future<List<Ticket>> getTickets() async {
    final db = await DBHelper.initDB();
    final result = await db.query('tickets', orderBy: 'id DESC');
    return result.map((e) => Ticket.fromMap(e)).toList();
  }
}
