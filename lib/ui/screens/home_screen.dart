import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import 'product_form.dart';
import 'ticket_screen.dart';
import '../../services/settings_service.dart';
import 'export_options_sheet.dart';
import 'ticket_history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> products = [];
  String businessName = "Inventario";
  String? logoPath;
  String? selectedCategory;
  List<String> categories = [];
  BannerAd? _bannerAd;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkInternetAndInitAd();
    _loadProducts();
    _loadSettings();
  }

  /// 🔌 Verifica conexión a internet antes de mostrar anuncios
  Future<void> _checkInternetAndInitAd() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      setState(() => _isOnline = false);
    } else {
      setState(() => _isOnline = true);
      _initBannerAd();
    }
  }

  void _initBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // ID de prueba
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() {}),
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Error al cargar banner: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final data = await ProductRepository.getProducts();
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
    setState(() {
      businessName = name ?? "Inventario";
      logoPath = logo;
    });
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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5F3FF), Color(0xFFFFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,

        appBar: AppBar(
          backgroundColor: Colors.white.withOpacity(0.9),
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
                        backgroundColor: Color(0xFFE0E0E0),
                        child: Icon(Icons.store, color: Colors.blueAccent),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  businessName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black87),
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
              icon: const Icon(Icons.picture_as_pdf, color: Colors.deepPurple),
              tooltip: 'Exportar inventario',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  builder: (context) => ExportOptionsSheet(products: products),
                );
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black87),
              onSelected: (value) {
                if (value == 'ticket') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TicketScreen()),
                  );
                } else if (value == 'historial') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TicketHistoryScreen()),
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
            // Filtro de categorías
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
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
                    onChanged: (val) => setState(() => selectedCategory = val),
                  ),
                ),
              ),
            ),

            // Lista de productos
            Expanded(
              child: productsByCategory.isEmpty
                  ? const Center(
                      child: Text(
                        "No hay productos aún",
                        style: TextStyle(color: Colors.black54),
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
                                fontSize: 18,
                              ),
                            ),
                            children: items.map((product) {
                              return ListTile(
                                leading: product.imagePath != null &&
                                        File(product.imagePath!).existsSync()
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(product.imagePath!),
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(Icons.inventory, size: 40),
                                title: Text(
                                  product.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                    "Precio: \$${product.price.toStringAsFixed(2)}"),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.deepPurple),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              ProductForm(product: product)),
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
          backgroundColor: Colors.deepPurple,
          elevation: 6,
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductForm()),
            );
            _loadProducts();
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipPath(
              clipper: CurvedNotchClipper(),
              child: Container(
                color: Colors.white.withOpacity(0.95),
                height: 70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.receipt_long,
                          color: Colors.deepPurple),
                      tooltip: 'Generar Ticket Digital',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TicketScreen()),
                        );
                      },
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.history, color: Colors.green),
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

            // 👇 Banner visible solo si hay conexión
            if (_isOnline && _bannerAd != null)
              Container(
                color: Colors.white,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
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
              _loadProducts();
            },
          ),
        ],
      ),
    );
  }
}

/// 🎨 Curva moderna en la barra inferior
class CurvedNotchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double notchRadius = 40;
    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2 - notchRadius, 0)
      ..quadraticBezierTo(size.width / 2, notchRadius * 1.6,
          size.width / 2 + notchRadius, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
