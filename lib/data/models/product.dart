class Product {
  final int? id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? imagePath; // NUEVO

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imagePath': imagePath,
    };
  }

  static Product fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'],
      category: map['category'],
      imagePath: map['imagePath'],
    );
  }
}
