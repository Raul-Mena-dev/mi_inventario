import 'package:flutter/material.dart';

import '../../data/models/customer.dart';
import '../../data/repositories/business_repository.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final data = await BusinessRepository.getCustomers();
    if (!mounted) return;
    setState(() => customers = data);
  }

  Future<void> _showCustomerForm([Customer? customer]) async {
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final notesController = TextEditingController(text: customer?.notes ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(customer == null ? 'Nuevo cliente' : 'Editar cliente'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Requerido'
                      : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
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
              final item = Customer(
                id: customer?.id,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                notes: notesController.text.trim(),
                createdAt:
                    customer?.createdAt ?? DateTime.now().toIso8601String(),
              );
              if (customer == null) {
                await BusinessRepository.insertCustomer(item);
              } else {
                await BusinessRepository.updateCustomer(item);
              }
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              await _loadCustomers();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    nameController.dispose();
    phoneController.dispose();
    notesController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: customers.isEmpty
          ? const Center(child: Text('No hay clientes registrados'))
          : ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(customer.name, maxLines: 1),
                  subtitle: Text(
                    [
                      if (customer.phone.isNotEmpty) customer.phone,
                      if (customer.notes.isNotEmpty) customer.notes,
                    ].join(' · '),
                    maxLines: 1,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showCustomerForm(customer),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCustomerForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
