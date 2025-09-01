import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../data/models/product.dart';

class PDFService {
  static Future<void> generateCatalog(List<Product> products) async {
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
            for (var entry in categories.entries) ...[
              pw.Header(
                level: 1,
                text: entry.key,
              ),
              for (var product in entry.value) pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (product.imagePath != null && File(product.imagePath!).existsSync())
                      pw.Container(
                        width: 60,
                        height: 60,
                        margin: const pw.EdgeInsets.only(right: 10),
                        child: pw.Image(
                          pw.MemoryImage(File(product.imagePath!).readAsBytesSync()),
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(product.name,
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          pw.Text(product.description,
                              style: pw.TextStyle(fontSize: 12)),
                          pw.Text("\$${product.price.toStringAsFixed(2)}",
                              style: pw.TextStyle(fontSize: 12, color: PdfColors.green)),
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

    final file = File("catalogo.pdf");
    await file.writeAsBytes(await pdf.save());
  }
}
