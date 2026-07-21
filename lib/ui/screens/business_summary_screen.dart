import 'package:flutter/material.dart';

import '../../data/database/ticket_repository.dart';
import '../../data/models/ticket.dart';
import '../../data/repositories/business_repository.dart';
import '../widgets/mock_ad_banner.dart';

class BusinessSummaryScreen extends StatefulWidget {
  const BusinessSummaryScreen({super.key});

  @override
  State<BusinessSummaryScreen> createState() => _BusinessSummaryScreenState();
}

class _BusinessSummaryScreenState extends State<BusinessSummaryScreen> {
  BusinessSummary? summary;
  List<ProductSalesSummary> topProducts = [];
  List<Ticket> pendingTickets = [];
  String selectedPeriod = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final range = _selectedRange();
    final nextSummary = await BusinessRepository.getSummary(
      from: range.$1,
      to: range.$2,
    );
    final nextTopProducts = await BusinessRepository.getTopProducts(
      from: range.$1,
      to: range.$2,
    );
    final nextPendingTickets = await BusinessRepository.getPendingTickets();
    if (!mounted) return;
    setState(() {
      summary = nextSummary;
      topProducts = nextTopProducts;
      pendingTickets = nextPendingTickets;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = summary;
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen del negocio')),
      body: data == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const MockAdBanner(placement: 'summary'),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'today', label: Text('Hoy')),
                      ButtonSegment(value: 'week', label: Text('Semana')),
                      ButtonSegment(value: 'month', label: Text('Mes')),
                      ButtonSegment(value: 'all', label: Text('Todo')),
                    ],
                    selected: {selectedPeriod},
                    onSelectionChanged: (selection) {
                      setState(() => selectedPeriod = selection.first);
                      _loadData();
                    },
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = (constraints.maxWidth - 10) / 2;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _MetricCard('Ventas', data.sales, Icons.point_of_sale,
                              width: width),
                          _MetricCard(
                              'Utilidad', data.profit, Icons.trending_up,
                              width: width),
                          _MetricCard('Gastos', data.expenses, Icons.payments,
                              width: width),
                          _MetricCard('Neto', data.netProfit, Icons.savings,
                              width: width),
                          _MetricCard(
                              'Por cobrar', data.pending, Icons.schedule,
                              width: width),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Alertas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ListTile(
                    leading: const Icon(Icons.warning_amber),
                    title: Text(
                        '${data.lowStockCount} producto(s) con stock bajo'),
                    subtitle: const Text('Revisa compras o reposición.'),
                  ),
                  const Divider(),
                  Text(
                    'Productos más vendidos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (topProducts.isEmpty)
                    const ListTile(
                        title: Text('Aún no hay ventas registradas')),
                  ...topProducts.map(
                    (item) => ListTile(
                      leading: const Icon(Icons.star_border),
                      title: Text(item.productName, maxLines: 1),
                      subtitle: Text('${item.quantity} vendido(s)'),
                      trailing: Text(
                        '\$${item.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const Divider(),
                  Text(
                    'Ventas pendientes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (pendingTickets.isEmpty)
                    const ListTile(title: Text('No hay saldos pendientes')),
                  ...pendingTickets.map(
                    (ticket) => ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text(
                        ticket.customerName.isEmpty
                            ? 'Cliente no registrado'
                            : ticket.customerName,
                        maxLines: 1,
                      ),
                      subtitle: Text(TicketRepository.displayDate(ticket.date)),
                      trailing: Text(
                        '\$${ticket.pendingAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  (DateTime?, DateTime?) _selectedRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (selectedPeriod) {
      case 'today':
        return (today, today.add(const Duration(days: 1)));
      case 'week':
        return (today.subtract(Duration(days: today.weekday - 1)), now);
      case 'month':
        return (DateTime(now.year, now.month), now);
      case 'all':
      default:
        return (null, null);
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final double width;

  const _MetricCard(this.label, this.value, this.icon, {required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, maxLines: 1),
              Text(
                '\$${value.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
