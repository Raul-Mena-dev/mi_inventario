import 'package:flutter/material.dart';
import 'dart:io';
import '../../data/models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const ProductCard(
      {super.key, required this.product, this.onDelete, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: product.imagePath != null
            ? Image.file(File(product.imagePath!),
                width: 50, height: 50, fit: BoxFit.cover)
            : Icon(Icons.inventory),
        title: Text(product.name),
        subtitle: Text("\$${product.price.toStringAsFixed(2)}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
