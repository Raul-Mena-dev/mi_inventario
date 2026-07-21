import 'package:flutter/material.dart';
import '../../data/models/ticket.dart';
import '../../data/database/ticket_repository.dart';
import '../../data/models/ticket_payment.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/mock_ad_banner.dart';

class TicketHistoryScreen extends StatefulWidget {
  const TicketHistoryScreen({super.key});

  @override
  State<TicketHistoryScreen> createState() => _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends State<TicketHistoryScreen> {
  List<Ticket> tickets = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    tickets = await TicketRepository.getTickets();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historial de Tickets")),
      body: tickets.isEmpty
          ? const Center(child: Text("No hay tickets recientes"))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: tickets.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const MockAdBanner(placement: 'ticket_history');
                }
                final ticketIndex = index - 1;
                final t = tickets[ticketIndex];
                return ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text(
                    "Ticket del ${TicketRepository.displayDate(t.date)}",
                    maxLines: 1,
                  ),
                  subtitle: Text(
                    [
                      "Total: \$${t.total.toStringAsFixed(2)}",
                      "Pago: ${TicketRepository.paymentLabel(t.paymentStatus)}",
                      if (t.customerName.isNotEmpty)
                        "Cliente: ${t.customerName}",
                      if (t.pendingAmount > 0)
                        "Saldo: \$${t.pendingAmount.toStringAsFixed(2)}",
                    ].join(" · "),
                    maxLines: 2,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'share') {
                        Share.shareXFiles([XFile(t.pdfPath)]);
                      } else if (value == 'open') {
                        OpenFile.open(t.pdfPath);
                      } else if (value == 'payment') {
                        _showPaymentDialog(t);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: Text('Compartir'),
                      ),
                      const PopupMenuItem(
                        value: 'open',
                        child: Text('Abrir'),
                      ),
                      if (t.pendingAmount > 0)
                        const PopupMenuItem(
                          value: 'payment',
                          child: Text('Registrar abono'),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showPaymentDialog(Ticket ticket) async {
    final amountController = TextEditingController(
      text: ticket.pendingAmount.toStringAsFixed(2),
    );
    final noteController = TextEditingController();
    List<TicketPayment> payments = [];
    if (ticket.id != null) {
      payments = await TicketRepository.getPayments(ticket.id!);
    }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Registrar abono'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Saldo: \$${ticket.pendingAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto recibido',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Nota',
                  border: OutlineInputBorder(),
                ),
              ),
              if (payments.isNotEmpty) ...[
                const Divider(height: 24),
                ...payments.map(
                  (payment) => ListTile(
                    dense: true,
                    title: Text('\$${payment.amount.toStringAsFixed(2)}'),
                    subtitle:
                        Text(TicketRepository.displayDate(payment.createdAt)),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) return;
              await TicketRepository.addPayment(
                ticket,
                amount,
                note: noteController.text.trim(),
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              await _loadTickets();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    amountController.dispose();
    noteController.dispose();
  }
}
