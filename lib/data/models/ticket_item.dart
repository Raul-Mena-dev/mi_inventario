import 'product.dart';

class TicketItem {
  final Product product;
  int quantity;

  TicketItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}
