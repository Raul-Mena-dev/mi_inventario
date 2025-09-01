import 'package:flutter/material.dart';
import 'dart:io';
import '../../data/models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onDelete;

  const ProductCard({Key? key, required this.product, this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: product.imagePath != null
          ? Image.file(File(product.imagePath!), width: 50, height: 50, fit: BoxFit.cover)
          : Icon(Icons.inventory),
        title: Text(product.name),
        subtitle: Text("\$${product.price.toStringAsFixed(2)}"),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
