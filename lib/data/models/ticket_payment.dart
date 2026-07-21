class TicketPayment {
  final int? id;
  final int ticketId;
  final double amount;
  final String note;
  final String createdAt;

  TicketPayment({
    this.id,
    required this.ticketId,
    required this.amount,
    this.note = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticketId': ticketId,
      'amount': amount,
      'note': note,
      'createdAt': createdAt,
    };
  }

  factory TicketPayment.fromMap(Map<String, dynamic> map) {
    return TicketPayment(
      id: map['id'] as int?,
      ticketId: (map['ticketId'] as int?) ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      note: (map['note'] ?? '') as String,
      createdAt: (map['createdAt'] ?? '') as String,
    );
  }
}
