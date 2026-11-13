import 'package:flutter/material.dart';

import '../app_state.dart';
import '../cart.dart';
import '../models.dart';
import '../theme.dart';
import '../whatsapp.dart';
import '../widgets.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return SafeArea(
      child: AnimatedBuilder(
        animation: state.cart,
        builder: (context, _) {
          final cart = state.cart;
          final rows = <(CartLine, Product)>[];
          for (final line in cart.lines) {
            final product = state.productById(line.productId);
            if (product != null) rows.add((line, product));
          }

          if (rows.isEmpty) {
            return Column(
              children: [
                const _Heading(count: 0),
                Expanded(
                  child: EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Your cart is empty',
                    message: 'Add the gadgets you like, then send your order to us on WhatsApp.',
                    actionLabel: 'Browse the shop',
                    onAction: () => state.selectedTab.value = 1,
                  ),
                ),
              ],
            );
          }

          final total = cart.total(state.products);
          return Column(
            children: [
              _Heading(count: cart.count),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  children: [
                    for (final (line, product) in rows) _CartRow(line: line, product: product),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estimated total',
                                style: TextStyle(color: Brand.muted, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              total == null ? 'We will confirm the total on WhatsApp' : ngn(total),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Brand.navy),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Nothing is paid in the app. We confirm availability and payment with you on WhatsApp.',
                              style: TextStyle(color: Brand.muted, height: 1.4, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Brand.line)),
                  ),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Brand.whatsapp),
                    onPressed: () => checkoutOnWhatsApp(context, _summary(rows, total)),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Order on WhatsApp'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _summary(List<(CartLine, Product)> rows, double? total) {
    final b = StringBuffer("Hello CHIANELSON, I'd like to order:\n");
    for (final (line, product) in rows) {
      final colour = line.colour == null ? '' : ' (${line.colour})';
      final each = product.price == null ? 'price on request' : ngn(product.price!);
      b.writeln('- ${product.name}$colour x${line.quantity}, $each');
    }
    b.writeln(total == null ? 'Please confirm the total.' : 'Total: ${ngn(total)}');
    b.write('Please confirm availability and how to pay.');
    return b.toString();
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Text(
        count == 0 ? 'Your cart' : 'Your cart ($count ${count == 1 ? 'item' : 'items'})',
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Brand.navy),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({required this.line, required this.product});

  final CartLine line;
  final Product product;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: 84, height: 84, child: ProductImage(url: product.coverUrl)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Brand.ink)),
                  if (line.colour != null)
                    Text('Colour: ${line.colour}', style: const TextStyle(color: Brand.muted, fontSize: 12)),
                  const SizedBox(height: 4),
                  PriceText(product, size: 15),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      QuantityStepper(
                        value: line.quantity,
                        onChanged: (q) => state.cart.setQuantity(line, q),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Remove',
                        onPressed: () => state.cart.remove(line),
                        icon: const Icon(Icons.delete_outline, color: Brand.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}