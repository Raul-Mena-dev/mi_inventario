import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../widgets/product_card.dart';
import 'product_form.dart';
import '../../services/pdf_service.dart';
import '../../services/settings_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> products = [];
  String businessName = "Inventario"; // valor por defecto

  @override
  void initState() {
    super.initState();
    loadProducts();
    loadBusinessName();
  }

  void loadProducts() async {
    final data = await ProductRepository.getProducts();
    setState(() => products = data);
  }

  void loadBusinessName() async {
    final name = await SettingsService.getBusinessName();
    setState(() {
      businessName = name ?? "Inventario";
    });
  }

  void _changeBusinessName() async {
    final controller = TextEditingController(text: businessName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Nombre del negocio"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Escribe el nombre de tu negocio"),
        ),
        actions: [
          TextButton(
            child: Text("Cancelar"),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: Text("Guardar"),
            onPressed: () => Navigator.pop(ctx, controller.text),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await SettingsService.saveBusinessName(newName);
      setState(() => businessName = newName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(businessName),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _changeBusinessName, // editar nombre
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () async {
              await PDFService.generateCatalog(products, businessName);
            },
          ),
        ],
      ),
      body: products.isEmpty
          ? Center(child: Text("No hay productos"))
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) => ProductCard(
                product: products[index],
                onDelete: () => _confirmDelete(products[index].id!),
                onEdit: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductForm(product: products[index]),
                    ),
                  );
                  loadProducts();
                },
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
}
