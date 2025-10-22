import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import 'product_form.dart';
import 'ticket_screen.dart';
import '../../services/settings_service.dart';
import 'export_options_sheet.dart';
import 'ticket_history_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> products = [];
  String businessName = "Inventario";
  String? selectedCategory;
  List<String> categories = [];

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
      categories = products.map((p) => p.category).toSet().toList();
      categories.sort();
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
        title: const Text("Nombre del negocio"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Escribe el nombre de tu negocio"),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text("Guardar"),
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
    final filteredProducts = selectedCategory == null
        ? products
        : products.where((p) => p.category == selectedCategory).toList();

    final Map<String, List<Product>> productsByCategory = {};
    for (var p in filteredProducts) {
      productsByCategory.putIfAbsent(p.category, () => []).add(p);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(businessName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Cambiar nombre del negocio',
            onPressed: _changeBusinessName,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar inventario',
            onPressed: () async {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => ExportOptionsSheet(
                  products: products,
                  businessName: businessName,
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'ticket') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TicketScreen()),
                );
              } else if (value == 'historial') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TicketHistoryScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'ticket',
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Ticket Digital'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'historial',
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Historial de Tickets'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text("Filtrar por categoría"),
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
          Expanded(
            child: productsByCategory.isEmpty
                ? const Center(child: Text("No hay productos"))
                : ListView(
                    children: productsByCategory.entries.map((entry) {
                      final category = entry.key;
                      final items = entry.value;

                      return ExpansionTile(
                        key: PageStorageKey(category),
                        title: Text(category,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        children: items.map((product) {
                          return ExpansionTile(
                            key: PageStorageKey(product.id),
                            leading: product.imagePath != null &&
                                    File(product.imagePath!).existsSync()
                                ? Image.file(
                                    File(product.imagePath!),
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.inventory, size: 40),
                            title: Text(product.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle:
                                Text("Categoría: ${product.category}"),
                            children: [
                              ListTile(
                                title: const Text("Descripción"),
                                subtitle: Text(product.description.isNotEmpty
                                    ? product.description
                                    : "Sin descripción"),
                              ),
                              ListTile(
                                title: const Text("Precio"),
                                subtitle: Text(
                                    "\$${product.price.toStringAsFixed(2)}"),
                              ),
                              if (product.imagePath != null &&
                                  File(product.imagePath!).existsSync())
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
                                    onPressed: () =>
                                        _confirmDelete(product.id!),
                                    child: const Text("Eliminar",
                                        style:
                                            TextStyle(color: Colors.red)),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ProductForm(product: product),
                                        ),
                                      );
                                      loadProducts();
                                    },
                                    child: const Text("Editar"),
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
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductForm()),
          );
          loadProducts();
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: Colors.blueGrey[50],
        elevation: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.receipt_long, color: Colors.blue),
              tooltip: 'Generar Ticket Digital',
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TicketScreen()));
              },
            ),
            IconButton(
              icon: const Icon(Icons.history, color: Colors.green),
              tooltip: 'Ver historial de tickets',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TicketHistoryScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar producto"),
        content: const Text("¿Seguro que deseas eliminar este producto?"),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
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
