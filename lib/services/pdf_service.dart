import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/product.dart';
import 'package:open_file/open_file.dart';
import 'settings_service.dart'; // 👈 para leer los datos guardados

class PdfService {
  /// Genera un catálogo en PDF, mostrando datos del negocio y redes sociales en texto
  static Future<void> generateProductPdf({
    required List<Product> products,
  }) async {
    final pdf = pw.Document();

    if (products.isEmpty) {
      print("⚠️ No hay productos para exportar.");
      return;
    }

    // 🔹 Obtener datos del negocio
    final businessName = await SettingsService.getBusinessName() ?? 'Mi Negocio';
    final logoPath = await SettingsService.getLogoPath();
    final socialLinks = await SettingsService.getSocialLinks(); 
    // socialLinks podría ser algo como: {'facebook': 'MiNegocioFB', 'instagram': '@minegocio', 'whatsapp': '3312345678'}

    // 🔹 Agrupar productos por categoría y subcategoría
    final Map<String, Map<String?, List<Product>>> grouped = {};

    for (var p in products) {
      final category = p.category;
      final subcategory = p.subcategory.isNotEmpty == true ? p.subcategory : null;

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
            if (logoPath != null && File(logoPath).existsSync())
              pw.Center(
                child: pw.Container(
                  width: 100,
                  height: 100,
                  child: pw.Image(
                    pw.MemoryImage(File(logoPath).readAsBytesSync()),
                    fit: pw.BoxFit.contain,
                  ),
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
                "Catálogo de productos",
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
                        if (product.imagePath != null &&
                            File(product.imagePath!).existsSync())
                          pw.Container(
                            width: 60,
                            height: 60,
                            margin: const pw.EdgeInsets.only(right: 10),
                            child: pw.Image(
                              pw.MemoryImage(
                                  File(product.imagePath!).readAsBytesSync()),
                              fit: pw.BoxFit.cover,
                            ),
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
            if (socialLinks != null && socialLinks.isNotEmpty) ...[
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
    final file = File('${directory.path}/catalogo_$timestamp.pdf');

    await file.writeAsBytes(await pdf.save());
    print('✅ PDF generado en: ${file.path}');

    // 🔹 Abrir el archivo
    await OpenFile.open(file.path);
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
