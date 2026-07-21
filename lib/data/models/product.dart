class Product {
  final int? id;
  final String name;
  final String description;
  final double price;
  final double cost;
  final int stock;
  final String category;
  final String subcategory;
  final String? imagePath;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    this.cost = 0,
    required this.stock,
    required this.category,
    required this.subcategory,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'cost': cost,
      'stock': stock,
      'category': category,
      'subcategory': subcategory,
      'imagePath': imagePath,
    };
  }

  static Product fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: (map['name'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      stock: (map['stock'] as int?) ?? 0,
      category: (map['category'] ?? '') as String,
      subcategory: (map['subcategory'] ?? '') as String,
      imagePath: map['imagePath'] as String?,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    double? cost,
    int? stock,
    String? category,
    String? subcategory,
    String? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
