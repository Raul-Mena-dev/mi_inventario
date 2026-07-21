import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/product.dart';
import '../../services/ad_service.dart';
import '../../services/pdf_service.dart';

class ExportOptionsSheet extends StatefulWidget {
  final List<Product> products;
  const ExportOptionsSheet({
    super.key,
    required this.products,
  });

  @override
  State<ExportOptionsSheet> createState() => _ExportOptionsSheetState();
}

class _ExportOptionsSheetState extends State<ExportOptionsSheet> {
  // Mapa: {categoria: {subcategoria: bool}}
  late Map<String, Map<String, bool>> selectedMap;
  bool showStock = false;
  bool shareAfterSave = true;
  bool isExporting = false;

  @override
  void initState() {
    super.initState();

    // Crear estructura base
    final Map<String, Map<String, bool>> map = {};
    for (var p in widget.products) {
      final category = p.category;
      final sub = p.subcategory.isNotEmpty ? p.subcategory : 'Sin subcategoría';
      map.putIfAbsent(category, () => {});
      map[category]!.putIfAbsent(sub, () => false);
    }

    selectedMap = map;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Selecciona qué exportar",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: controller,
                children: selectedMap.entries.map((catEntry) {
                  final category = catEntry.key;
                  final subMap = catEntry.value;

                  final allSelected = subMap.values.every((v) => v);
                  final someSelected = subMap.values.any((v) => v);

                  return ExpansionTile(
                    title: Row(
                      children: [
                        Checkbox(
                          value:
                              someSelected && !allSelected ? null : allSelected,
                          tristate: someSelected && !allSelected,
                          onChanged: isExporting
                              ? null
                              : (val) {
                                  setState(() {
                                    for (var sub in subMap.keys) {
                                      subMap[sub] = val ?? false;
                                    }
                                  });
                                },
                        ),
                        Expanded(
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    children: subMap.entries.map((entry) {
                      final sub = entry.key;
                      final checked = entry.value;
                      return CheckboxListTile(
                        value: checked,
                        onChanged: isExporting
                            ? null
                            : (val) {
                                setState(() {
                                  subMap[sub] = val ?? false;
                                });
                              },
                        title: Text(sub, maxLines: 1),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: showStock,
              onChanged: isExporting
                  ? null
                  : (value) => setState(() => showStock = value),
              title: const Text("Mostrar stock"),
              subtitle: const Text(
                "Apágalo para catálogo de venta",
                maxLines: 1,
              ),
            ),
            SwitchListTile(
              value: shareAfterSave,
              onChanged: isExporting
                  ? null
                  : (value) => setState(() => shareAfterSave = value),
              title: const Text("Compartir al terminar"),
            ),
            ElevatedButton.icon(
              icon: isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(shareAfterSave ? Icons.share : Icons.picture_as_pdf),
              label: Text(isExporting
                  ? "Generando"
                  : showStock
                      ? "Exportar"
                      : "Catálogo"),
              onPressed: isExporting ? null : _exportSelected,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportSelected() async {
    // Obtener las combinaciones seleccionadas
    final selectedPairs = <MapEntry<String, String>>[];
    selectedMap.forEach((cat, subMap) {
      subMap.forEach((sub, selected) {
        if (selected) selectedPairs.add(MapEntry(cat, sub));
      });
    });

    if (selectedPairs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecciona al menos una categoría o subcategoría"),
        ),
      );
      return;
    }

    // Filtrar productos según las combinaciones seleccionadas
    final filteredProducts = widget.products.where((p) {
      final sub = p.subcategory.isNotEmpty ? p.subcategory : 'Sin subcategoría';
      return selectedPairs.any((pair) {
        return pair.key == p.category && pair.value == sub;
      });
    }).toList();

    setState(() => isExporting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await PdfService.generateProductPdf(
        products: filteredProducts,
        showStock: showStock,
      );
      if (!mounted || file == null) return;

      if (shareAfterSave) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(file.path)],
          text: showStock ? 'Inventario de productos' : 'Catálogo de productos',
          sharePositionOrigin:
              box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        );
      }

      if (!mounted) return;
      await AdService.maybeShowInterstitial(
        context,
        title: 'Anuncio de prueba',
        message: 'Aquí se mostraría un anuncio después de generar el catálogo.',
      );
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text("PDF generado correctamente")),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text("No se pudo generar el PDF. Intenta de nuevo."),
        ),
      );
    } finally {
      if (mounted) setState(() => isExporting = false);
    }
  }
}
