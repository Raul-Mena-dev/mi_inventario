class Reminder {
  final int? id;
  final String title;
  final String notes;
  final String type;
  final String scheduledAt;
  final String status;
  final int? customerId;
  final String customerName;
  final int? ticketId;
  final String ticketLabel;
  final String createdAt;
  final String? completedAt;

  Reminder({
    this.id,
    required this.title,
    this.notes = '',
    required this.type,
    required this.scheduledAt,
    this.status = 'pending',
    this.customerId,
    this.customerName = '',
    this.ticketId,
    this.ticketLabel = '',
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'type': type,
      'scheduledAt': scheduledAt,
      'status': status,
      'customerId': customerId,
      'customerName': customerName,
      'ticketId': ticketId,
      'ticketLabel': ticketLabel,
      'createdAt': createdAt,
      'completedAt': completedAt,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      title: (map['title'] ?? '') as String,
      notes: (map['notes'] ?? '') as String,
      type: (map['type'] ?? 'other') as String,
      scheduledAt: (map['scheduledAt'] ?? '') as String,
      status: (map['status'] ?? 'pending') as String,
      customerId: map['customerId'] as int?,
      customerName: (map['customerName'] ?? '') as String,
      ticketId: map['ticketId'] as int?,
      ticketLabel: (map['ticketLabel'] ?? '') as String,
      createdAt: (map['createdAt'] ?? '') as String,
      completedAt: map['completedAt'] as String?,
    );
  }

  Reminder copyWith({
    int? id,
    String? title,
    String? notes,
    String? type,
    String? scheduledAt,
    String? status,
    int? customerId,
    String? customerName,
    int? ticketId,
    String? ticketLabel,
    String? createdAt,
    String? completedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      ticketId: ticketId ?? this.ticketId,
      ticketLabel: ticketLabel ?? this.ticketLabel,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
