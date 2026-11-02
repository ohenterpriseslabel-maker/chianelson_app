import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import '../models.dart';
import '../widgets.dart';

/// Order tracking. CHIANELSON creates an order here once payment is confirmed on WhatsApp, and updates its stage.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Future<List<Order>>? _orders;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (!state.signedIn) {
      _orders = null;
      return const SafeArea(child: NeedsSignIn(icon: Icons.local_shipping_outlined, message: 'Sign in with the phone number you use on WhatsApp to track your orders.'));
    }
    final future = _orders ??= state.repo.orders();
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() => _orders = state.repo.orders());
          await _orders;
        },
        child: FutureBuilder<List<Order>>(
          future: future,
          builder: (context, snap) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text('Your orders', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Orders appear here after we confirm your payment on WhatsApp.', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 16),
                if (snap.connectionState != ConnectionState.done)
                  const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                else if (snap.hasError)
                  const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Your orders could not be loaded. Pull down to try again.')))
                else if ((snap.data ?? const <Order>[]).isEmpty)
                  const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No orders yet.')))
                else
                  for (final order in snap.data!) _OrderCard(order),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard(this.order);
  final Order order;

  @override
  Widget build(BuildContext context) {
    final current = orderSteps.indexOf(order.status).clamp(0, orderSteps.length - 1);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(order.reference, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1))),
              Text(formatDate(order.createdAt), style: const TextStyle(fontSize: 12, color: Colors.black45)),
            ]),
            const SizedBox(height: 6),
            Text(order.summary),
            const SizedBox(height: 16),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: (current + 1) / orderSteps.length, minHeight: 6, color: AppConfig.gold, backgroundColor: const Color(0xFFEDE6D6))),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < orderSteps.length; i++)
                  Expanded(
                    child: Column(
                      children: [
                        Icon(i <= current ? Icons.check_circle : Icons.radio_button_unchecked, size: 22, color: i <= current ? AppConfig.navy : Colors.black26),
                        const SizedBox(height: 4),
                        Text(orderStepLabel(orderSteps[i]), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: i == current ? FontWeight.w700 : FontWeight.w400)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Last updated ${formatDate(order.updatedAt)}', style: const TextStyle(fontSize: 12, color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}