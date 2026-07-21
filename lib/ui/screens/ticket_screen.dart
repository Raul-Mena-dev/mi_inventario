import 'package:flutter/material.dart';
import '../../data/models/customer.dart';
import '../../data/models/product.dart';
import '../../data/models/ticket_item.dart';
import '../../data/repositories/business_repository.dart';
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
  List<Customer> customers = [];
  Customer? selectedCustomer;
  String? selectedCategory;
  String searchQuery = "";
  String paymentStatus = 'paid';
  final TextEditingController _paidAmountController = TextEditingController();
  bool isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final allProducts = await ProductRepository.getProducts();
    final allCategories = await ProductRepository.getCategories();
    final allCustomers = await BusinessRepository.getCustomers();

    if (!mounted) return;
    setState(() {
      products = allProducts;
      categories = allCategories;
      customers = allCustomers;
    });
  }

  double get total => selectedItems.fold(0, (sum, item) => sum + item.total);

  double get paidAmount {
    if (paymentStatus == 'paid') return total;
    if (paymentStatus == 'pending') return 0;
    final parsed = double.tryParse(_paidAmountController.text.trim()) ?? 0;
    if (parsed < 0) return 0;
    if (parsed > total) return total;
    return parsed;
  }

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
    if (isGenerating) return;
    if (paymentStatus == 'partial' &&
        (_paidAmountController.text.trim().isEmpty || paidAmount <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa el abono recibido")),
      );
      return;
    }

    final stockErrors = await ProductRepository.validateStock(selectedItems);
    if (stockErrors.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(stockErrors.first)),
      );
      return;
    }

    try {
      setState(() => isGenerating = true);
      await TicketPDFService.generateTicket(
        List<TicketItem>.from(selectedItems),
        customer: selectedCustomer,
        paymentStatus: paymentStatus,
        paidAmount: paidAmount,
      );
      await ProductRepository.decrementStock(selectedItems);
      await _loadInitialData();
      if (!mounted) return;
      setState(() {
        selectedItems.clear();
        selectedCustomer = null;
        paymentStatus = 'paid';
        _paidAmountController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ticket generado correctamente")),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo generar el ticket. Intenta de nuevo."),
        ),
      );
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  @override
  void dispose() {
    _paidAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: DropdownButtonFormField<int?>(
              initialValue: selectedCustomer?.id,
              decoration: const InputDecoration(
                labelText: "Cliente",
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text("Venta general")),
                ...customers.map(
                  (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedCustomer = value == null
                      ? null
                      : customers.firstWhere((c) => c.id == value);
                });
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: paymentStatus,
                    decoration: const InputDecoration(
                      labelText: "Pago",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'paid', child: Text('Pagado')),
                      DropdownMenuItem(
                          value: 'partial', child: Text('Parcial')),
                      DropdownMenuItem(
                          value: 'pending', child: Text('Pendiente')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => paymentStatus = value);
                    },
                  ),
                ),
                if (paymentStatus == 'partial') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _paidAmountController,
                      decoration: const InputDecoration(
                        labelText: "Abono",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ],
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
                        title: Text(p.name, maxLines: 1),
                        subtitle: Text(
                          "\$${p.price.toStringAsFixed(2)} · Stock: ${p.stock}",
                          maxLines: 1,
                        ),
                        enabled: p.stock > 0,
                        tileColor: p.stock <= 3
                            ? Colors.orange.withValues(alpha: 0.08)
                            : null,
                        trailing: SizedBox(
                          width: 104,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                onPressed: () => _updateQuantity(p, -1),
                              ),
                              SizedBox(
                                width: 20,
                                child: Text(
                                  "${existing.quantity}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
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
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // 🧮 Total y generación de PDF
      bottomNavigationBar: Container(
        color: colors.surfaceContainerHighest,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Total: \$${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: selectedItems.isEmpty || isGenerating
                    ? null
                    : _generateTicket,
                icon: isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf, size: 18),
                label: Text(isGenerating ? "Guardando" : "Ticket"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
