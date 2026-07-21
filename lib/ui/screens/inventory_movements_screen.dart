import 'package:flutter/material.dart';

import '../../data/models/inventory_movement.dart';
import '../../data/repositories/inventory_movement_repository.dart';

class InventoryMovementsScreen extends StatefulWidget {
  const InventoryMovementsScreen({super.key});

  @override
  State<InventoryMovementsScreen> createState() =>
      _InventoryMovementsScreenState();
}

class _InventoryMovementsScreenState extends State<InventoryMovementsScreen> {
  List<InventoryMovement> movements = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    final data = await InventoryMovementRepository.getMovements();
    if (!mounted) return;
    setState(() {
      movements = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Movimientos de inventario")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : movements.isEmpty
              ? const Center(child: Text("No hay movimientos registrados"))
              : RefreshIndicator(
                  onRefresh: _loadMovements,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: movements.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final movement = movements[index];
                      final isEntry = movement.quantityChange > 0;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isEntry
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          child: Icon(
                            isEntry ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isEntry ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(movement.productName, maxLines: 1),
                        subtitle: Text(
                          "${movement.reason} · Stock final: ${movement.stockAfter}",
                          maxLines: 1,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatQuantity(movement.quantityChange),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isEntry ? Colors.green : Colors.red,
                              ),
                            ),
                            Text(
                              _formatDate(movement.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatQuantity(int value) {
    return value > 0 ? "+$value" : "$value";
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$day/$month $hour:$minute";
  }
}
