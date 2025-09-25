import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import 'product_form.dart';
import '../../services/pdf_service.dart';
import '../../services/settings_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> products = [];
  String businessName = "Inventario";
  String? selectedCategory;
  List<String> categories = []; // categorías únicas

  @override
  void initState() {
    super.initState();
    loadProducts();
    loadBusinessName();
  }

  void loadProducts() async {
    final data = await ProductRepository.getProducts();
    setState(() {
      products = data;

      // actualizar categorías únicas
      categories = products.map((p) => p.category).toSet().toList();
      categories.sort();

      // limpiar categoría seleccionada si ya no existe
      if (selectedCategory != null && !categories.contains(selectedCategory)) {
        selectedCategory = null;
      }
    });
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
    // filtrar productos según categoría seleccionada
    final filteredProducts = selectedCategory == null
        ? products
        : products.where((p) => p.category == selectedCategory).toList();

    // agrupar productos por categoría
    final Map<String, List<Product>> productsByCategory = {};
    for (var p in filteredProducts) {
      productsByCategory.putIfAbsent(p.category, () => []).add(p);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(businessName),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _changeBusinessName,
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () async {
              await PDFService.generateCatalog(filteredProducts, businessName);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Dropdown de filtro por categoría
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text("Filtrar por categoría"),
              value: selectedCategory,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text("Todas las categorías"),
                ),
                ...categories.map(
                  (c) => DropdownMenuItem(value: c, child: Text(c)),
                ),
              ],
              onChanged: (val) {
                setState(() => selectedCategory = val);
              },
            ),
          ),
          // Lista de productos agrupados
          Expanded(
            child: productsByCategory.isEmpty
                ? Center(child: Text("No hay productos"))
                : ListView(
                    children: productsByCategory.entries.map((entry) {
                      final category = entry.key;
                      final items = entry.value;

                      return ExpansionTile(
                        key: PageStorageKey(category), // mantener estado abierto
                        title: Text(
                          category,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        children: items.map((product) {
                          return ExpansionTile(
                            key: PageStorageKey(product.id), // mantener estado abierto
                            leading: product.imagePath != null &&
                                    File(product.imagePath!).existsSync()
                                ? Image.file(
                                    File(product.imagePath!),
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(Icons.inventory, size: 40),
                            title: Text(product.name, style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Categoría: ${product.category}"),
                            children: [
                              ListTile(
                                title: Text("Descripción"),
                                subtitle: Text(product.description.isNotEmpty
                                    ? product.description
                                    : "Sin descripción"),
                              ),
                              ListTile(
                                title: Text("Precio"),
                                subtitle: Text("\$${product.price.toStringAsFixed(2)}"),
                              ),
                              if (product.imagePath != null && File(product.imagePath!).existsSync())
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.file(
                                    File(product.imagePath!),
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              OverflowBar(
                                children: [
                                  TextButton(
                                    onPressed: () => _confirmDelete(product.id!),
                                    child: Text("Eliminar", style: TextStyle(color: Colors.red)),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductForm(product: product),
                                        ),
                                      );
                                      loadProducts();
                                    },
                                    child: Text("Editar"),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
          ),
        ],
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
