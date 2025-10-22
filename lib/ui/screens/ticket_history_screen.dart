import 'package:flutter/material.dart';
import '../../data/models/ticket.dart';
import '../../data/database/ticket_repository.dart';
import 'package:open_file/open_file.dart';

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
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final t = tickets[index];
                return ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text("Ticket del ${t.date}"),
                  subtitle: Text("Total: \$${t.total.toStringAsFixed(2)}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => OpenFile.open(t.pdfPath),
                  ),
                );
              },
            ),
    );
  }
}
