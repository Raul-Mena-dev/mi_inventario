class Expense {
  final int? id;
  final String concept;
  final double amount;
  final String category;
  final String createdAt;
  final String notes;

  Expense({
    this.id,
    required this.concept,
    required this.amount,
    required this.category,
    required this.createdAt,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'concept': concept,
      'amount': amount,
      'category': category,
      'createdAt': createdAt,
      'notes': notes,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      concept: (map['concept'] ?? '') as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      category: (map['category'] ?? '') as String,
      createdAt: (map['createdAt'] ?? '') as String,
      notes: (map['notes'] ?? '') as String,
    );
  }
}
