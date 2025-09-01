import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../widgets/product_card.dart';
import 'product_form.dart';
import '../../services/pdf_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  void _confirmDelete(int id) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text("Eliminar producto"),
      content: Text("¿Seguro que deseas eliminar este producto?"),
      actions: [
        TextButton(
          child: Text("Cancelar"),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
        TextButton(
          child: Text("Eliminar", style: TextStyle(color: Colors.red)),
          onPressed: () async {
            await ProductRepository.deleteProduct(id);
            Navigator.of(ctx).pop();
            loadProducts();
          },
        ),
      ],
    ),
  );
}


  void loadProducts() async {
    final data = await ProductRepository.getProducts();
    setState(() => products = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Inventario"),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () async {
              await PDFService.generateCatalog(products);
            },
          )
        ],
      ),
      body: products.isEmpty
          ? Center(child: Text("No hay productos"))
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) => ProductCard(
                product: products[index],
                onDelete: () => _confirmDelete(products[index].id!),
              ),
            ),

      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductForm()),
          );
          loadProducts();
        },
      ),
    );
  }
}
