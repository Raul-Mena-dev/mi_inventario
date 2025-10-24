import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../data/models/product.dart';
import '../data/models/ticket.dart';
import '../data/database/ticket_repository.dart';
import 'settings_service.dart';

class TicketPDFService {
  static Future<void> generateTicket(
    String businessName,
    List<Product> products,
  ) async {
    final pdf = pw.Document();
    final total = products.fold<double>(0, (sum, p) => sum + (p.price ?? 0));
    final date = DateTime.now();
    final formattedDate =
        "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

    // 🔹 Cargar ajustes del negocio
    final name = await SettingsService.getBusinessName() ?? 'Mi Negocio';
    final logoPath = await SettingsService.getLogoPath();
    final links = await SettingsService.getSocialLinks(); // {'facebook': 'MiNegocio', 'whatsapp': '3312345678'}

    // 🔹 Construir la página del ticket
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll57, // formato tipo recibo
        margin: const pw.EdgeInsets.all(10),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // --- LOGO + NOMBRE ---
            if (logoPath != null && File(logoPath).existsSync())
              pw.Center(
                child: pw.Container(
                  height: 60,
                  width: 60,
                  child: pw.Image(
                    pw.MemoryImage(File(logoPath).readAsBytesSync()),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
            pw.Text(
              name,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              "Ticket de venta",
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.normal),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              "Fecha: $formattedDate",
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Divider(thickness: 0.8),

            // --- TABLA DE PRODUCTOS ---
            pw.Table(
              border: pw.TableBorder.all(width: 0.3),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'Producto',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'Precio',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...products.map(
                  (p) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          p.name ?? '',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          "\$${p.price?.toStringAsFixed(2) ?? '0.00'}",
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.Divider(thickness: 0.8),

            // --- TOTAL ---
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Total: \$${total.toStringAsFixed(2)}",
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 10),

            // --- REDES SOCIALES COMO TEXTO ---
            if (links != null && links.isNotEmpty)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    "Síguenos en:",
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: links.entries
                        .where((e) => e.value.isNotEmpty)
                        .map(
                          (e) => pw.Text(
                            "${_formatSocialName(e.key)}: ${e.value}",
                            style: pw.TextStyle(fontSize: 9),
                            textAlign: pw.TextAlign.center,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),

            pw.SizedBox(height: 8),
            pw.Text(
              "¡Gracias por su compra!",
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
          ],
        ),
      ),
    );

    // 🔹 Guardar archivo PDF
    final output = await getApplicationDocumentsDirectory();
    final filename = "ticket_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File("${output.path}/$filename");
    await file.writeAsBytes(await pdf.save());

    // 🔹 Guardar ticket en base de datos
    final ticket = Ticket(
      date: formattedDate,
      total: total,
      pdfPath: file.path,
    );
    await TicketRepository.insertTicket(ticket);

    await OpenFile.open(file.path);
  }

  static String _formatSocialName(String key) {
    switch (key.toLowerCase()) {
      case 'facebook':
        return "Facebook";
      case 'instagram':
        return "Instagram";
      case 'tiktok':
        return "TikTok";
      case 'x':
        return "X";
      case 'whatsapp':
        return "WhatsApp";
      default:
        return key[0].toUpperCase() + key.substring(1);
    }
  }
}
