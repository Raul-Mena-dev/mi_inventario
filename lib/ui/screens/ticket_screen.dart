import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../data/models/ticket_item.dart';
import '../../data/repositories/product_repository.dart';
import '../../services/settings_service.dart';
import '../../services/ticket_pdf_service.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  List<Product> products = [];
  List<TicketItem> selectedItems = [];
  List<String> categories = [];
  String? selectedCategory;
  String searchQuery = "";
  String businessName = "Mi Negocio";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final allProducts = await ProductRepository.getProducts();
    final allCategories = await ProductRepository.getCategories();
    final name = await SettingsService.getBusinessName();

    setState(() {
      products = allProducts;
      categories = allCategories;
      businessName = name ?? "Mi Negocio";
    });
  }

  double get total =>
      selectedItems.fold(0, (sum, item) => sum + item.total);

  List<Product> get filteredProducts {
    List<Product> filtered = products;

    if (selectedCategory != null && selectedCategory!.isNotEmpty) {
      filtered = filtered
          .where((p) => p.category == selectedCategory)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  void _updateQuantity(Product p, int change) {
    setState(() {
      final existing = selectedItems.firstWhere(
        (item) => item.product == p,
        orElse: () => TicketItem(product: p, quantity: 0),
      );

      if (existing.quantity + change <= 0) {
        selectedItems.removeWhere((item) => item.product == p);
      } else {
        if (existing.quantity == 0 && change > 0) {
          selectedItems.add(TicketItem(product: p, quantity: 1));
        } else {
          existing.quantity += change;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generar Ticket")),
      body: Column(
        children: [
          // 🔍 Barra de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Buscar producto...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),

          // 🏷️ Filtro por categoría
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: "Filtrar por categoría",
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text("Todas")),
                ...categories.map(
                  (c) => DropdownMenuItem(value: c, child: Text(c)),
                ),
              ],
              onChanged: (value) => setState(() => selectedCategory = value),
            ),
          ),

          // 🧾 Lista de productos
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(child: Text("No hay productos"))
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = filteredProducts[index];
                      final existing = selectedItems.firstWhere(
                        (item) => item.product == p,
                        orElse: () => TicketItem(product: p, quantity: 0),
                      );

                      return ListTile(
                        title: Text(p.name ?? ''),
                        subtitle:
                            Text("\$${p.price?.toStringAsFixed(2) ?? '0.00'}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.red),
                              onPressed: () => _updateQuantity(p, -1),
                            ),
                            Text(
                              "${existing.quantity}",
                              style: const TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle,
                                  color: Colors.green),
                              onPressed: () => _updateQuantity(p, 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // 🧮 Total y generación de PDF
      bottomNavigationBar: Container(
        color: Colors.grey.shade200,
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Total: \$${total.toStringAsFixed(2)}",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: selectedItems.isEmpty
                  ? null
                  : () async {
                      await TicketPDFService.generateTicket(
                        businessName,
                        selectedItems.map((t) => t.product).toList(),
                      );
                      setState(() => selectedItems.clear());
                    },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Generar Ticket"),
            ),
          ],
        ),
      ),
    );
  }
}
