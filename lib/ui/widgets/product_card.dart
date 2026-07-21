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
        leading:
            product.imagePath != null && File(product.imagePath!).existsSync()
                ? Image.file(File(product.imagePath!),
                    width: 50, height: 50, fit: BoxFit.cover)
                : const Icon(Icons.inventory),
        title: Text(product.name, maxLines: 1),
        subtitle: Text(
          "\$${product.price.toStringAsFixed(2)} · Stock: ${product.stock}",
          maxLines: 1,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit?.call();
            if (value == 'delete') onDelete?.call();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }
}
