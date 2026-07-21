import 'package:flutter/material.dart';
import '../../data/models/product.dart';
import '../../data/models/ticket_item.dart';
import '../../data/repositories/product_repository.dart';
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

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final allProducts = await ProductRepository.getProducts();
    final allCategories = await ProductRepository.getCategories();

    if (!mounted) return;
    setState(() {
      products = allProducts;
      categories = allCategories;
    });
  }

  double get total => selectedItems.fold(0, (sum, item) => sum + item.total);

  List<Product> get filteredProducts {
    List<Product> filtered = products;

    if (selectedCategory != null && selectedCategory!.isNotEmpty) {
      filtered = filtered.where((p) => p.category == selectedCategory).toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  void _updateQuantity(Product p, int change) {
    setState(() {
      final existing = selectedItems.firstWhere(
        (item) => item.product.id == p.id,
        orElse: () => TicketItem(product: p, quantity: 0),
      );

      if (existing.quantity + change <= 0) {
        selectedItems.removeWhere((item) => item.product.id == p.id);
      } else if (existing.quantity + change > p.stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Solo hay ${p.stock} disponibles")),
        );
      } else {
        if (existing.quantity == 0 && change > 0) {
          selectedItems.add(TicketItem(product: p, quantity: 1));
        } else {
          existing.quantity += change;
        }
      }
    });
  }

  Future<void> _generateTicket() async {
    final stockErrors = await ProductRepository.validateStock(selectedItems);
    if (stockErrors.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(stockErrors.first)),
      );
      return;
    }

    try {
      await TicketPDFService.generateTicket(
        List<TicketItem>.from(selectedItems),
      );
      await ProductRepository.decrementStock(selectedItems);
      await _loadInitialData();
      if (!mounted) return;
      setState(() => selectedItems.clear());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo generar el ticket: $error")),
      );
    }
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
              initialValue: selectedCategory,
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
                        (item) => item.product.id == p.id,
                        orElse: () => TicketItem(product: p, quantity: 0),
                      );

                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text(
                          "\$${p.price.toStringAsFixed(2)} · Stock: ${p.stock}",
                        ),
                        enabled: p.stock > 0,
                        tileColor: p.stock <= 3
                            ? Colors.orange.withValues(alpha: 0.08)
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () => _updateQuantity(p, -1),
                            ),
                            Text(
                              "${existing.quantity}",
                              style: const TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.green,
                              ),
                              onPressed: existing.quantity >= p.stock
                                  ? null
                                  : () => _updateQuantity(p, 1),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: selectedItems.isEmpty ? null : _generateTicket,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Generar Ticket"),
            ),
          ],
        ),
      ),
    );
  }
}
