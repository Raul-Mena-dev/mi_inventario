import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/product.dart';
import 'package:open_file/open_file.dart';

class PdfService {
  /// Genera un catálogo en PDF, filtrando opcionalmente por categoría o subcategoría
  static Future<void> generateProductPdf({
    required List<Product> products,
    required String businessName,
  }) async {
    final pdf = pw.Document();

    if (products.isEmpty) {
      print("⚠️ No hay productos para exportar.");
      return;
    }

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
            // Título principal
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
            pw.SizedBox(height: 20),

            // 🔹 Recorrer categorías
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

              // 🔹 Recorrer subcategorías
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

                // 🔹 Productos dentro de esa subcategoría
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
}
