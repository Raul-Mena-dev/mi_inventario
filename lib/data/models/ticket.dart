class Ticket {
  final int? id;
  final String date;
  final double total;
  final String pdfPath;
  final int? customerId;
  final String customerName;
  final String paymentStatus;
  final double paidAmount;
  final double profit;

  Ticket({
    this.id,
    required this.date,
    required this.total,
    required this.pdfPath,
    this.customerId,
    this.customerName = '',
    this.paymentStatus = 'paid',
    double? paidAmount,
    this.profit = 0,
  }) : paidAmount = paidAmount ?? total;

  double get pendingAmount {
    final pending = total - paidAmount;
    return pending < 0 ? 0 : pending;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'total': total,
        'pdfPath': pdfPath,
        'customerId': customerId,
        'customerName': customerName,
        'paymentStatus': paymentStatus,
        'paidAmount': paidAmount,
        'profit': profit,
      };

  factory Ticket.fromMap(Map<String, dynamic> map) => Ticket(
        id: map['id'] as int?,
        date: (map['date'] ?? '') as String,
        total: (map['total'] as num?)?.toDouble() ?? 0,
        pdfPath: (map['pdfPath'] ?? '') as String,
        customerId: map['customerId'] as int?,
        customerName: (map['customerName'] ?? '') as String,
        paymentStatus: (map['paymentStatus'] ?? 'paid') as String,
        paidAmount: (map['paidAmount'] as num?)?.toDouble(),
        profit: (map['profit'] as num?)?.toDouble() ?? 0,
      );
}
