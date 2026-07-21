import 'package:flutter/material.dart';

import '../../data/database/ticket_repository.dart';
import '../../data/models/customer.dart';
import '../../data/models/reminder.dart';
import '../../data/models/ticket.dart';
import '../../data/repositories/business_repository.dart';
import '../../data/repositories/reminder_repository.dart';
import '../../services/notification_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Reminder> reminders = [];
  List<Customer> customers = [];
  List<Ticket> tickets = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final nextReminders = await ReminderRepository.getReminders();
    final nextCustomers = await BusinessRepository.getCustomers();
    final nextTickets = await TicketRepository.getTickets();
    if (!mounted) return;
    setState(() {
      reminders = nextReminders;
      customers = nextCustomers;
      tickets = nextTickets;
      loading = false;
    });
  }

  Future<void> _showReminderForm() async {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime scheduledAt = DateTime.now().add(const Duration(hours: 1));
    String type = 'collect';
    Customer? selectedCustomer;
    Ticket? selectedTicket;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo recordatorio'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Requerido'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'collect', child: Text('Cobrar')),
                      DropdownMenuItem(
                          value: 'dispatch', child: Text('Despachar')),
                      DropdownMenuItem(
                          value: 'follow_up', child: Text('Seguimiento')),
                      DropdownMenuItem(value: 'other', child: Text('Otro')),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => type = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    initialValue: selectedCustomer?.id,
                    decoration: const InputDecoration(
                      labelText: 'Cliente',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Ninguno')),
                      ...customers.map(
                        (customer) => DropdownMenuItem(
                          value: customer.id,
                          child: Text(customer.name, maxLines: 1),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCustomer = value == null
                            ? null
                            : customers.firstWhere((c) => c.id == value);
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    initialValue: selectedTicket?.id,
                    decoration: const InputDecoration(
                      labelText: 'Ticket',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Ninguno')),
                      ...tickets.take(30).map(
                            (ticket) => DropdownMenuItem(
                              value: ticket.id,
                              child: Text(_ticketLabel(ticket), maxLines: 1),
                            ),
                          ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedTicket = value == null
                            ? null
                            : tickets.firstWhere((t) => t.id == value);
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: Text(_formatDateTime(scheduledAt)),
                    subtitle: const Text('Fecha y hora de alerta'),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                        initialDate: scheduledAt,
                      );
                      if (date == null || !context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(scheduledAt),
                      );
                      if (time == null) return;
                      setDialogState(() {
                        scheduledAt = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    },
                  ),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notas',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (scheduledAt.isBefore(DateTime.now())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Elige una fecha futura')),
                  );
                  return;
                }

                final ticket = selectedTicket;
                final reminder = Reminder(
                  title: titleController.text.trim(),
                  notes: notesController.text.trim(),
                  type: type,
                  scheduledAt: scheduledAt.toIso8601String(),
                  customerId: selectedCustomer?.id,
                  customerName: selectedCustomer?.name ?? '',
                  ticketId: ticket?.id,
                  ticketLabel: ticket == null ? '' : _ticketLabel(ticket),
                  createdAt: DateTime.now().toIso8601String(),
                );
                final id = await ReminderRepository.insertReminder(reminder);
                await NotificationService.scheduleReminder(
                  reminder.copyWith(id: id),
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                await _loadData();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    notesController.dispose();
  }

  Future<void> _completeReminder(Reminder reminder) async {
    final id = reminder.id;
    if (id == null) return;
    await ReminderRepository.completeReminder(reminder);
    await NotificationService.cancelReminder(id);
    await _loadData();
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final id = reminder.id;
    if (id == null) return;
    await ReminderRepository.deleteReminder(id);
    await NotificationService.cancelReminder(id);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final pending = reminders.where((r) => r.status == 'pending').toList();
    final completed = reminders.where((r) => r.status == 'completed').toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Recordatorios')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                children: [
                  if (pending.isEmpty)
                    const ListTile(
                        title: Text('No hay recordatorios pendientes')),
                  ...pending.map(_buildReminderTile),
                  if (completed.isNotEmpty) ...[
                    const Divider(height: 28),
                    Text(
                      'Completados',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ...completed.map(_buildReminderTile),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showReminderForm,
        child: const Icon(Icons.add_alert),
      ),
    );
  }

  Widget _buildReminderTile(Reminder reminder) {
    final isCompleted = reminder.status == 'completed';
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(
          _typeIcon(reminder.type),
          color: isCompleted
              ? colors.onSurface.withValues(alpha: 0.55)
              : colors.primary,
        ),
        title: Text(reminder.title, maxLines: 1),
        subtitle: Text(
          [
            _formatDateTime(DateTime.tryParse(reminder.scheduledAt)),
            if (reminder.customerName.isNotEmpty) reminder.customerName,
            if (reminder.ticketLabel.isNotEmpty) reminder.ticketLabel,
            if (reminder.notes.isNotEmpty) reminder.notes,
          ].whereType<String>().join(' · '),
          maxLines: 2,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'complete') _completeReminder(reminder);
            if (value == 'delete') _deleteReminder(reminder);
          },
          itemBuilder: (context) => [
            if (!isCompleted)
              const PopupMenuItem(value: 'complete', child: Text('Completar')),
            const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'collect':
        return Icons.attach_money;
      case 'dispatch':
        return Icons.local_shipping;
      case 'follow_up':
        return Icons.phone_forwarded;
      default:
        return Icons.notifications_active;
    }
  }

  String _ticketLabel(Ticket ticket) {
    return 'Ticket ${ticket.id ?? '-'} · \$${ticket.total.toStringAsFixed(2)}';
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }
}
