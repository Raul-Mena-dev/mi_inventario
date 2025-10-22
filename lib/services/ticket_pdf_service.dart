import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../data/models/product.dart';
import '../data/models/ticket.dart';
import '../data/database/ticket_repository.dart';

class TicketPDFService {
  static Future<void> generateTicket(
    String businessName,
    List<Product> products,
  ) async {
    final pdf = pw.Document();
    final total = products.fold<double>(0, (sum, p) => sum + (p.price ?? 0));
    final date = DateTime.now().toString();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                businessName,
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Center(child: pw.Text("Ticket de venta", style: pw.TextStyle(fontSize: 14))),
            pw.SizedBox(height: 10),
            pw.Text("Fecha: $date"),
            pw.Divider(),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Producto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Precio', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                ...products.map(
                  (p) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(p.name ?? ''),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text("\$${p.price?.toStringAsFixed(2) ?? '0.00'}"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Total: \$${total.toStringAsFixed(2)}",
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final filename = "ticket_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File("${output.path}/$filename");
    await file.writeAsBytes(await pdf.save());

    // Guardar ticket en BD
    final ticket = Ticket(date: date, total: total, pdfPath: file.path);
    await TicketRepository.insertTicket(ticket);

    await OpenFile.open(file.path);
  }
}
