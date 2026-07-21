import '../database/db_helper.dart';
import '../models/ticket.dart';
import '../models/ticket_item.dart';
import '../models/ticket_payment.dart';

class TicketRepository {
  static Future<int> insertTicket(
    Ticket ticket, {
    List<TicketItem> items = const [],
  }) async {
    final db = await DBHelper.initDB();
    return db.transaction((txn) async {
      final id = await txn.insert('tickets', ticket.toMap());
      for (final item in items) {
        final unitCost = item.product.cost;
        await txn.insert('ticket_items', {
          'ticketId': id,
          'productId': item.product.id,
          'productName': item.product.name,
          'quantity': item.quantity,
          'unitPrice': item.product.price,
          'unitCost': unitCost,
          'total': item.total,
          'profit': (item.product.price - unitCost) * item.quantity,
        });
      }
      if (ticket.paidAmount > 0) {
        await txn.insert(
          'ticket_payments',
          TicketPayment(
            ticketId: id,
            amount: ticket.paidAmount,
            note: 'Pago inicial',
            createdAt: DateTime.now().toIso8601String(),
          ).toMap(),
        );
      }
      return id;
    });
  }

  static Future<int> updatePayment({
    required int ticketId,
    required String paymentStatus,
    required double paidAmount,
  }) async {
    final db = await DBHelper.initDB();
    return db.update(
      'tickets',
      {
        'paymentStatus': paymentStatus,
        'paidAmount': paidAmount,
      },
      where: 'id = ?',
      whereArgs: [ticketId],
    );
  }

  static Future<int> addPayment(Ticket ticket, double amount,
      {String note = ''}) async {
    final ticketId = ticket.id;
    if (ticketId == null) {
      throw StateError('Ticket sin id');
    }
    if (amount <= 0) {
      throw ArgumentError('El abono debe ser mayor a cero');
    }

    final db = await DBHelper.initDB();
    return db.transaction((txn) async {
      final nextPaid = (ticket.paidAmount + amount).clamp(0, ticket.total);
      final nextStatus = nextPaid >= ticket.total ? 'paid' : 'partial';
      final id = await txn.insert(
        'ticket_payments',
        TicketPayment(
          ticketId: ticketId,
          amount: amount,
          note: note,
          createdAt: DateTime.now().toIso8601String(),
        ).toMap(),
      );
      await txn.update(
        'tickets',
        {
          'paidAmount': nextPaid,
          'paymentStatus': nextStatus,
        },
        where: 'id = ?',
        whereArgs: [ticketId],
      );
      return id;
    });
  }

  static Future<List<TicketPayment>> getPayments(int ticketId) async {
    final db = await DBHelper.initDB();
    final rows = await db.query(
      'ticket_payments',
      where: 'ticketId = ?',
      whereArgs: [ticketId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(TicketPayment.fromMap).toList();
  }

  static Future<List<Map<String, dynamic>>> getTicketItems(int ticketId) async {
    final db = await DBHelper.initDB();
    return db.query(
      'ticket_items',
      where: 'ticketId = ?',
      whereArgs: [ticketId],
      orderBy: 'id ASC',
    );
  }

  static Future<void> backfillTicketItemsForLegacyTicket({
    required int ticketId,
    required List<TicketItem> items,
  }) async {
    final db = await DBHelper.initDB();
    await db.transaction((txn) async {
      final existing = await txn.query(
        'ticket_items',
        where: 'ticketId = ?',
        whereArgs: [ticketId],
        limit: 1,
      );
      if (existing.isNotEmpty) return;
      for (final item in items) {
        await txn.insert('ticket_items', {
          'ticketId': ticketId,
          'productId': item.product.id,
          'productName': item.product.name,
          'quantity': item.quantity,
          'unitPrice': item.product.price,
          'unitCost': item.product.cost,
          'total': item.total,
          'profit': (item.product.price - item.product.cost) * item.quantity,
        });
      }
      final profit = items.fold<double>(
        0,
        (sum, item) =>
            sum + ((item.product.price - item.product.cost) * item.quantity),
      );
      await txn.update(
        'tickets',
        {'profit': profit},
        where: 'id = ?',
        whereArgs: [ticketId],
      );
    });
  }

  static Future<void> markPaid(Ticket ticket) async {
    final id = ticket.id;
    if (id == null) return;
    await updatePayment(
      ticketId: id,
      paymentStatus: 'paid',
      paidAmount: ticket.total,
    );
  }

  static String paymentLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'partial':
        return 'Parcial';
      case 'paid':
      default:
        return 'Pagado';
    }
  }

  static String displayDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$day/$month/${parsed.year} ${parsed.hour}:$minute';
  }

  static double calculateProfit(List<TicketItem> items) {
    return items.fold<double>(
      0,
      (sum, item) =>
          sum + ((item.product.price - item.product.cost) * item.quantity),
    );
  }

  static Future<List<Ticket>> getTickets() async {
    final db = await DBHelper.initDB();
    final result = await db.query('tickets', orderBy: 'id DESC');
    return result.map((e) => Ticket.fromMap(e)).toList();
  }
}
