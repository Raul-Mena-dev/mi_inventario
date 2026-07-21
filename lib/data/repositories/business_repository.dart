import '../database/db_helper.dart';
import '../models/customer.dart';
import '../models/expense.dart';
import '../models/ticket.dart';

class BusinessSummary {
  final double sales;
  final double profit;
  final double expenses;
  final double pending;
  final int lowStockCount;
  final int ticketCount;

  BusinessSummary({
    required this.sales,
    required this.profit,
    required this.expenses,
    required this.pending,
    required this.lowStockCount,
    required this.ticketCount,
  });

  double get netProfit => profit - expenses;
}

class ProductSalesSummary {
  final String productName;
  final int quantity;
  final double total;

  ProductSalesSummary({
    required this.productName,
    required this.quantity,
    required this.total,
  });
}

class BusinessRepository {
  static Future<int> insertCustomer(Customer customer) async {
    final db = await DBHelper.initDB();
    return db.insert('customers', customer.toMap());
  }

  static Future<int> updateCustomer(Customer customer) async {
    final db = await DBHelper.initDB();
    return db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  static Future<int> deleteCustomer(int id) async {
    final db = await DBHelper.initDB();
    return db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Customer>> getCustomers() async {
    final db = await DBHelper.initDB();
    final rows = await db.query('customers', orderBy: 'name COLLATE NOCASE');
    return rows.map(Customer.fromMap).toList();
  }

  static Future<int> insertExpense(Expense expense) async {
    final db = await DBHelper.initDB();
    return db.insert('expenses', expense.toMap());
  }

  static Future<int> deleteExpense(int id) async {
    final db = await DBHelper.initDB();
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Expense>> getExpenses({int limit = 50}) async {
    final db = await DBHelper.initDB();
    final rows = await db.query(
      'expenses',
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return rows.map(Expense.fromMap).toList();
  }

  static Future<BusinessSummary> getSummary({
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await DBHelper.initDB();
    final range = _rangeWhere(from, to);
    final salesRows = await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(total), 0) AS sales,
        COALESCE(SUM(profit), 0) AS profit,
        COALESCE(SUM(total - paidAmount), 0) AS pending,
        COUNT(*) AS ticketCount
      FROM tickets
      ${range.ticketWhere}
      ''',
      range.args,
    );
    final expenseRows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS expenses
      FROM expenses
      ${range.expenseWhere}
      ''',
      range.args,
    );
    final lowStockRows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM products WHERE stock <= 3',
    );

    final sales = salesRows.first;
    return BusinessSummary(
      sales: (sales['sales'] as num?)?.toDouble() ?? 0,
      profit: (sales['profit'] as num?)?.toDouble() ?? 0,
      pending: (sales['pending'] as num?)?.toDouble() ?? 0,
      ticketCount: (sales['ticketCount'] as int?) ?? 0,
      expenses: (expenseRows.first['expenses'] as num?)?.toDouble() ?? 0,
      lowStockCount: (lowStockRows.first['count'] as int?) ?? 0,
    );
  }

  static Future<List<ProductSalesSummary>> getTopProducts({
    int limit = 5,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await DBHelper.initDB();
    final range = _ticketItemRangeWhere(from, to);
    final rows = await db.rawQuery(
      '''
      SELECT ti.productName, SUM(ti.quantity) AS quantity, SUM(ti.total) AS total
      FROM ticket_items ti
      INNER JOIN tickets t ON t.id = ti.ticketId
      ${range.where}
      GROUP BY ti.productName
      ORDER BY quantity DESC, total DESC
      LIMIT ?
      ''',
      [...range.args, limit],
    );
    return rows
        .map(
          (row) => ProductSalesSummary(
            productName: (row['productName'] ?? '') as String,
            quantity: (row['quantity'] as int?) ?? 0,
            total: (row['total'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList();
  }

  static Future<List<Ticket>> getPendingTickets() async {
    final db = await DBHelper.initDB();
    final rows = await db.query(
      'tickets',
      where: 'paymentStatus != ? AND total > paidAmount',
      whereArgs: ['paid'],
      orderBy: 'id DESC',
    );
    return rows.map(Ticket.fromMap).toList();
  }

  static _SummaryRange _rangeWhere(DateTime? from, DateTime? to) {
    if (from == null && to == null) return _SummaryRange('', '', []);

    final clauses = <String>[];
    final args = <String>[];
    if (from != null) {
      clauses.add('createdAt >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      clauses.add('createdAt <= ?');
      args.add(to.toIso8601String());
    }
    final ticketWhere = 'WHERE ${clauses.join(' AND ')}'.replaceAll(
      'createdAt',
      'date',
    );
    final expenseWhere = 'WHERE ${clauses.join(' AND ')}';
    return _SummaryRange(ticketWhere, expenseWhere, args);
  }

  static _QueryRange _ticketItemRangeWhere(DateTime? from, DateTime? to) {
    if (from == null && to == null) return _QueryRange('', []);

    final clauses = <String>[];
    final args = <String>[];
    if (from != null) {
      clauses.add('t.date >= ?');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      clauses.add('t.date <= ?');
      args.add(to.toIso8601String());
    }
    return _QueryRange('WHERE ${clauses.join(' AND ')}', args);
  }
}

class _SummaryRange {
  final String ticketWhere;
  final String expenseWhere;
  final List<String> args;

  _SummaryRange(this.ticketWhere, this.expenseWhere, this.args);
}

class _QueryRange {
  final String where;
  final List<String> args;

  _QueryRange(this.where, this.args);
}
