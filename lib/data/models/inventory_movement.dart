class InventoryMovement {
  final int? id;
  final int productId;
  final String productName;
  final int quantityChange;
  final int stockAfter;
  final String reason;
  final String createdAt;

  InventoryMovement({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantityChange,
    required this.stockAfter,
    required this.reason,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantityChange': quantityChange,
      'stockAfter': stockAfter,
      'reason': reason,
      'createdAt': createdAt,
    };
  }

  factory InventoryMovement.fromMap(Map<String, dynamic> map) {
    return InventoryMovement(
      id: map['id'] as int?,
      productId: (map['productId'] as int?) ?? 0,
      productName: (map['productName'] ?? '') as String,
      quantityChange: (map['quantityChange'] as int?) ?? 0,
      stockAfter: (map['stockAfter'] as int?) ?? 0,
      reason: (map['reason'] ?? '') as String,
      createdAt: (map['createdAt'] ?? '') as String,
    );
  }
}
