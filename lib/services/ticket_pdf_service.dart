import 'dart:io';

import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

import '../data/database/ticket_repository.dart';
import '../data/models/ticket.dart';
import '../data/models/ticket_item.dart';
import 'settings_service.dart';

class TicketPDFService {
  static Future<void> generateTicket(
    List<TicketItem> items,
  ) async {
    final pdf = pw.Document();
    final total = items.fold<double>(0, (sum, item) => sum + item.total);
    final date = DateTime.now();
    final formattedDate =
        "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";

    // 🔹 Cargar ajustes del negocio
    final name = await SettingsService.getBusinessName() ?? 'Mi Negocio';
    final logoPath = await SettingsService.getLogoPath();
    final links = (await SettingsService.getSocialLinks())
      ..removeWhere((key, value) => value.trim().isEmpty);

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
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.normal,
              ),
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
                    _cell('Producto', bold: true),
                    _cell('Cant.', bold: true, alignRight: true),
                    _cell('Subtotal', bold: true, alignRight: true),
                  ],
                ),
                ...items.map(
                  (item) => pw.TableRow(
                    children: [
                      _cell(
                        '${item.product.name}\n\$${item.product.price.toStringAsFixed(2)} c/u',
                      ),
                      _cell('${item.quantity}', alignRight: true),
                      _cell(
                        "\$${item.total.toStringAsFixed(2)}",
                        alignRight: true,
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
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),

            // --- REDES SOCIALES COMO TEXTO ---
            if (links.isNotEmpty)
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

    try {
      await OpenFile.open(file.path);
    } catch (_) {
      // The ticket is already saved; opening depends on the device apps.
    }
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

  static pw.Widget _cell(
    String value, {
    bool bold = false,
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        value,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
