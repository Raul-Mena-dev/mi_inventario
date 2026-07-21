import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../services/settings_service.dart';
import 'business_summary_screen.dart';
import 'customers_screen.dart';
import 'export_options_sheet.dart';
import 'expenses_screen.dart';
import 'image_viewer_screen.dart';
import 'inventory_movements_screen.dart';
import 'product_form.dart';
import 'reminders_screen.dart';
import 'settings_screen.dart';
import 'ticket_history_screen.dart';
import 'ticket_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> products = [];
  String businessName = "Inventario";
  String? logoPath;
  String? selectedCategory;
  String searchQuery = "";
  List<String> categories = [];
  bool showLowStockOnly = false;
  static const int lowStockThreshold = 3;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadSettings();
  }

  Future<void> _loadProducts() async {
    final data = await ProductRepository.getProducts();
    if (!mounted) return;
    setState(() {
      products = data;
      categories = products.map((p) => p.category).toSet().toList()..sort();
      if (selectedCategory != null && !categories.contains(selectedCategory)) {
        selectedCategory = null;
      }
    });
  }

  Future<void> _loadSettings() async {
    final name = await SettingsService.getBusinessName();
    final logo = await SettingsService.getLogoPath();
    if (!mounted) return;
    setState(() {
      businessName = name ?? "Inventario";
      logoPath = logo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final filteredProducts = products.where((p) {
      final matchesCategory =
          selectedCategory == null || p.category == selectedCategory;
      final query = searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query) ||
          p.subcategory.toLowerCase().contains(query);
      final matchesLowStock = !showLowStockOnly || p.stock <= lowStockThreshold;
      return matchesCategory && matchesSearch && matchesLowStock;
    }).toList();

    final Map<String, List<Product>> productsByCategory = {};
    for (var p in filteredProducts) {
      productsByCategory.putIfAbsent(p.category, () => []).add(p);
    }
    final lowStockCount =
        products.where((p) => p.stock <= lowStockThreshold).length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryContainer, colors.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: colors.surface.withValues(alpha: 0.92),
          elevation: 4,
          titleSpacing: 8,
          title: Row(
            children: [
              Hero(
                tag: 'logoHero',
                child: logoPath != null && File(logoPath!).existsSync()
                    ? CircleAvatar(
                        backgroundImage: FileImage(File(logoPath!)),
                        radius: 20,
                      )
                    : const CircleAvatar(
                        radius: 20,
                        child: Icon(Icons.store),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  businessName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: colors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Configuración del negocio',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
                _loadSettings();
              },
            ),
            IconButton(
              icon: Icon(Icons.picture_as_pdf, color: colors.primary),
              tooltip: 'Exportar inventario',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: colors.surface,
                  builder: (context) => ExportOptionsSheet(
                    products: products,
                  ),
                );
              },
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colors.onSurface),
              onSelected: (value) async {
                if (value == 'ticket') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TicketScreen()),
                  );
                  _loadProducts();
                } else if (value == 'historial') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TicketHistoryScreen(),
                    ),
                  );
                } else if (value == 'movimientos') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InventoryMovementsScreen(),
                    ),
                  );
                } else if (value == 'resumen') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BusinessSummaryScreen(),
                    ),
                  );
                } else if (value == 'clientes') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomersScreen()),
                  );
                } else if (value == 'gastos') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExpensesScreen()),
                  );
                } else if (value == 'recordatorios') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RemindersScreen(),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'resumen',
                  child: Row(
                    children: [
                      Icon(Icons.dashboard, color: Colors.teal),
                      SizedBox(width: 8),
                      Text('Resumen del negocio'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'recordatorios',
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Recordatorios'),
                    ],
                  ),
                ),
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
                  value: 'clientes',
                  child: Row(
                    children: [
                      Icon(Icons.people, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text('Clientes'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'gastos',
                  child: Row(
                    children: [
                      Icon(Icons.payments, color: Colors.brown),
                      SizedBox(width: 8),
                      Text('Gastos'),
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
                const PopupMenuItem(
                  value: 'movimientos',
                  child: Row(
                    children: [
                      Icon(Icons.swap_vert, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text('Movimientos'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            if (lowStockCount > 0)
              MaterialBanner(
                content: Text(
                  "$lowStockCount producto(s) con stock bajo",
                ),
                leading: const Icon(Icons.warning_amber, color: Colors.orange),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedCategory = null;
                        searchQuery = "";
                        showLowStockOnly = true;
                      });
                    },
                    child: const Text("Ver"),
                  ),
                ],
              ),
            if (showLowStockOnly)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(child: Text("Mostrando stock bajo")),
                    TextButton(
                      onPressed: () {
                        setState(() => showLowStockOnly = false);
                      },
                      child: const Text("Quitar"),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Buscar producto...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colors.surface.withValues(alpha: 0.92),
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
            ),
            // Filtro
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    underline: const SizedBox(),
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
                      setState(() {
                        selectedCategory = val;
                        showLowStockOnly = false;
                      });
                    },
                  ),
                ),
              ),
            ),

            // Lista
            Expanded(
              child: productsByCategory.isEmpty
                  ? Center(
                      child: Text(
                        "No hay productos aún",
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: 0.68),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(10),
                      children: productsByCategory.entries.map((entry) {
                        final category = entry.key;
                        final items = entry.value;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ExpansionTile(
                            key: PageStorageKey(category),
                            title: Text(
                              category,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                            ),
                            children: items.map((product) {
                              return ListTile(
                                leading: product.imagePath != null &&
                                        File(product.imagePath!).existsSync()
                                    ? GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ImageViewerScreen(
                                                imagePath: product.imagePath!,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Hero(
                                          tag: product.imagePath!,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.file(
                                              File(product.imagePath!),
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.inventory, size: 40),
                                title: Text(
                                  product.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                ),
                                subtitle: Text(
                                  "Precio: \$${product.price.toStringAsFixed(2)} · Costo: \$${product.cost.toStringAsFixed(2)} · Stock: ${product.stock}",
                                  maxLines: 2,
                                ),
                                tileColor: product.stock <= lowStockThreshold
                                    ? Colors.orange.withValues(alpha: 0.08)
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.deepPurple),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ProductForm(product: product),
                                      ),
                                    );
                                    _loadProducts();
                                  },
                                ),
                                onLongPress: () => _confirmDelete(product.id!),
                              );
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Agregar producto',
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductForm()),
            );
            _loadProducts();
          },
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: BottomAppBar(
          color: colors.surface.withValues(alpha: 0.95),
          elevation: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.dashboard, color: Colors.teal),
                tooltip: 'Resumen del negocio',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BusinessSummaryScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.receipt_long, color: Colors.blue),
                tooltip: 'Generar Ticket Digital',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TicketScreen()),
                  );
                  _loadProducts();
                },
              ),
              IconButton(
                icon: const Icon(Icons.swap_vert, color: Colors.deepPurple),
                tooltip: 'Ver movimientos',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InventoryMovementsScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications_active,
                    color: Colors.orange),
                tooltip: 'Recordatorios',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RemindersScreen(),
                    ),
                  );
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
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              _loadProducts();
            },
          ),
        ],
      ),
    );
  }
}
