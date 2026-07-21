class Customer {
  final int? id;
  final String name;
  final String phone;
  final String notes;
  final String createdAt;

  Customer({
    this.id,
    required this.name,
    this.phone = '',
    this.notes = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: (map['name'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      notes: (map['notes'] ?? '') as String,
      createdAt: (map['createdAt'] ?? '') as String,
    );
  }
}
