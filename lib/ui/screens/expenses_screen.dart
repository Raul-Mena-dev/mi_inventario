import 'package:flutter/material.dart';

import '../../data/models/expense.dart';
import '../../data/repositories/business_repository.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Expense> expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final data = await BusinessRepository.getExpenses();
    if (!mounted) return;
    setState(() => expenses = data);
  }

  Future<void> _showExpenseForm() async {
    final conceptController = TextEditingController();
    final amountController = TextEditingController();
    final categoryController = TextEditingController(text: 'General');
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nuevo gasto'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: conceptController,
                  decoration: const InputDecoration(labelText: 'Concepto'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Requerido'
                      : null,
                ),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Monto'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null || amount <= 0) return 'Monto inválido';
                    return null;
                  },
                ),
                TextFormField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                ),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notas'),
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
              await BusinessRepository.insertExpense(
                Expense(
                  concept: conceptController.text.trim(),
                  amount: double.parse(amountController.text.trim()),
                  category: categoryController.text.trim().isEmpty
                      ? 'General'
                      : categoryController.text.trim(),
                  notes: notesController.text.trim(),
                  createdAt: DateTime.now().toIso8601String(),
                ),
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              await _loadExpenses();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    conceptController.dispose();
    amountController.dispose();
    categoryController.dispose();
    notesController.dispose();
  }

  String _displayDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<double>(0, (sum, item) => sum + item.amount);
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.payments),
            title: const Text('Total registrado'),
            trailing: Text(
              '\$${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: expenses.isEmpty
                ? const Center(child: Text('No hay gastos registrados'))
                : ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return ListTile(
                        leading: const Icon(Icons.receipt),
                        title: Text(expense.concept, maxLines: 1),
                        subtitle: Text(
                          '${expense.category} · ${_displayDate(expense.createdAt)}',
                          maxLines: 1,
                        ),
                        trailing: Text(
                          '\$${expense.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        onLongPress: () async {
                          final id = expense.id;
                          if (id == null) return;
                          await BusinessRepository.deleteExpense(id);
                          await _loadExpenses();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showExpenseForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
