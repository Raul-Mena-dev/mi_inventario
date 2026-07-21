import 'dart:io';

import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

import '../data/models/product.dart';
import 'settings_service.dart';

class PdfService {
  /// Genera un catálogo en PDF, mostrando datos del negocio y redes sociales en texto
  static Future<File?> generateProductPdf({
    required List<Product> products,
    bool showStock = true,
  }) async {
    final pdf = pw.Document();

    if (products.isEmpty) {
      return null;
    }

    // 🔹 Obtener datos del negocio
    final businessName =
        await SettingsService.getBusinessName() ?? 'Mi Negocio';
    final logoPath = await SettingsService.getLogoPath();
    final logoImage = _loadPdfImage(logoPath);
    final socialLinks = (await SettingsService.getSocialLinks())
      ..removeWhere((key, value) => value.trim().isEmpty);

    // 🔹 Agrupar productos por categoría y subcategoría
    final Map<String, Map<String?, List<Product>>> grouped = {};

    for (var p in products) {
      final category = p.category;
      final subcategory = p.subcategory.isNotEmpty ? p.subcategory : null;

      grouped.putIfAbsent(category, () => {});
      grouped[category]!.putIfAbsent(subcategory, () => []);
      grouped[category]![subcategory]!.add(p);
    }

    // 🔹 Construir el contenido del PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            // 🔹 Encabezado del catálogo
            if (logoImage != null)
              pw.Center(
                child: pw.Container(
                  width: 100,
                  height: 100,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              ),
            pw.Center(
              child: pw.Text(
                businessName,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                showStock ? "Inventario de productos" : "Catálogo de productos",
                style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),
            ),
            pw.SizedBox(height: 20),

            // 🔹 Contenido principal (productos agrupados)
            for (var catEntry in grouped.entries) ...[
              pw.Header(
                level: 1,
                text: catEntry.key,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey, width: 1),
                  ),
                ),
              ),
              for (var subEntry in catEntry.value.entries) ...[
                if (subEntry.key != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
                    child: pw.Text(
                      "Subcategoría: ${subEntry.key}",
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo,
                      ),
                    ),
                  ),
                for (var product in subEntry.value)
                  pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 6),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (_loadPdfImage(product.imagePath) case final image?)
                          pw.Container(
                            width: 60,
                            height: 60,
                            margin: const pw.EdgeInsets.only(right: 10),
                            child: pw.Image(image, fit: pw.BoxFit.cover),
                          ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(product.name,
                                  style: pw.TextStyle(
                                      fontSize: 14,
                                      fontWeight: pw.FontWeight.bold)),
                              if (product.description.isNotEmpty)
                                pw.Text(product.description,
                                    style: pw.TextStyle(fontSize: 12)),
                              pw.Text(
                                "\$${product.price.toStringAsFixed(2)}",
                                style: pw.TextStyle(
                                    fontSize: 12, color: PdfColors.green800),
                              ),
                              if (showStock)
                                pw.Text(
                                  "Stock: ${product.stock}",
                                  style: pw.TextStyle(fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                pw.Divider(),
              ],
            ],

            pw.SizedBox(height: 20),

            // 🔹 Pie con redes sociales
            if (socialLinks.isNotEmpty) ...[
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  "Síguenos en nuestras redes sociales",
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Column(
                  children: socialLinks.entries
                      .map((e) => pw.Text(
                            "${_capitalize(e.key)}: ${e.value}",
                            style: pw.TextStyle(fontSize: 11),
                          ))
                      .toList(),
                ),
              ),
            ],
          ];
        },
      ),
    );

    // 🔹 Guardar el archivo
    final directory = await getApplicationDocumentsDirectory();
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final prefix = showStock ? 'inventario' : 'catalogo';
    final file = File('${directory.path}/${prefix}_$timestamp.pdf');

    await file.writeAsBytes(await pdf.save());
    try {
      await OpenFile.open(file.path);
    } catch (_) {
      // The PDF is saved even when the device has no app to open it.
    }
    return file;
  }

  static pw.MemoryImage? _loadPdfImage(String? path) {
    if (path == null) return null;
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      return pw.MemoryImage(file.readAsBytesSync());
    } catch (_) {
      return null;
    }
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
