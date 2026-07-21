import 'package:flutter/material.dart';

import '../../data/models/product.dart';
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
            const Text("Selecciona qué exportar",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          onChanged: (val) {
                            setState(() {
                              for (var sub in subMap.keys) {
                                subMap[sub] = val ?? false;
                              }
                            });
                          },
                        ),
                        Text(
                          category,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    children: subMap.entries.map((entry) {
                      final sub = entry.key;
                      final checked = entry.value;
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (val) {
                          setState(() {
                            subMap[sub] = val ?? false;
                          });
                        },
                        title: Text(sub),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Exportar PDF"),
              onPressed: _exportSelected,
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

    Navigator.pop(context); // Cerrar modal

    await PdfService.generateProductPdf(
      products: filteredProducts,
    );
  }
}
