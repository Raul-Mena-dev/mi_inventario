class Ticket {
  final int? id;
  final String date;
  final double total;
  final String pdfPath;

  Ticket(
      {this.id,
      required this.date,
      required this.total,
      required this.pdfPath});

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'total': total,
        'pdfPath': pdfPath,
      };

  factory Ticket.fromMap(Map<String, dynamic> map) => Ticket(
        id: map['id'],
        date: map['date'],
        total: map['total'],
        pdfPath: map['pdfPath'],
      );
}
