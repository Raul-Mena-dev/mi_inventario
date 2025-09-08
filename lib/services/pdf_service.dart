import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/product.dart';
import 'package:open_file/open_file.dart';

class PDFService {
  static Future<void> generateCatalog(List<Product> products, String businessName) async {
    final pdf = pw.Document();

    // Agrupar por categoría
    final categories = <String, List<Product>>{};
    for (var p in products) {
      categories.putIfAbsent(p.category, () => []).add(p);
    }

    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            // 🚀 Título del negocio
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

            // 🚀 Listado por categorías
            for (var entry in categories.entries) ...[
              pw.Header(
                level: 1,
                text: entry.key,
              ),
              for (var product in entry.value)
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
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
                            pw.Text(product.description,
                                style: pw.TextStyle(fontSize: 12)),
                            pw.Text("\$${product.price.toStringAsFixed(2)}",
                                style: pw.TextStyle(
                                    fontSize: 12, color: PdfColors.green)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              pw.Divider(),
            ]
          ];
        },
      ),
    );

    // 🚀 Cambiar la ruta para iOS/Android segura
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/catalogo.pdf');
    await file.writeAsBytes(await pdf.save());

    print('PDF generado en: ${file.path}');

    final result = await OpenFile.open(file.path);
    print(result); // te dice si se abrió correctamente
  }
}
