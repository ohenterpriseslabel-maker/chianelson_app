import 'package:flutter/material.dart';

import '../admin_repository.dart';
import '../models.dart';

/// Creates orders after payment is confirmed on WhatsApp, and moves each one through the stages the customer sees.
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _repo = AdminRepository();
  late Future<List<AdminOrder>> _orders = _repo.orders();

  void _reload() {
    setState(() => _orders = _repo.orders());
  }

  Future<void> _newOrder() async {
    final saved = await showDialog<bool>(context: context, builder: (_) => const _NewOrderDialog());
    if (saved == true && mounted) _reload();
  }

  Future<void> _setStatus(AdminOrder order, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.setOrderStatus(order.id, status);
      if (mounted) _reload();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('The order could not be updated. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders and tracking')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _newOrder, icon: const Icon(Icons.add), label: const Text('New order')),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _orders;
        },
        child: FutureBuilder<List<AdminOrder>>(
          future: _orders,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return const Center(child: Text('Orders could not be loaded. Pull down to try again.'));
            final orders = snap.data ?? const <AdminOrder>[];
            if (orders.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No orders yet. Tap New order after you confirm payment on WhatsApp.', textAlign: TextAlign.center)));
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: orders.length,
              itemBuilder: (_, i) => _OrderTile(order: orders[i], onStatus: (s) => _setStatus(orders[i], s)),
            );
          },
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onStatus});
  final AdminOrder order;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) {
    final who = order.customerName.isEmpty ? order.customerPhone : order.customerName;
    final amount = order.amount == null ? 'No amount' : naira(order.amount!);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        isThreeLine: true,
        title: Text('${order.reference} · $who'),
        subtitle: Text('${order.summary}\n$amount · ${orderStepLabel(order.status)}'),
        trailing: PopupMenuButton<String>(
          tooltip: 'Change stage',
          icon: const Icon(Icons.more_vert),
          onSelected: onStatus,
          itemBuilder: (_) => [
            for (final s in orderSteps)
              PopupMenuItem<String>(value: s, enabled: s != order.status, child: Text(orderStepLabel(s))),
          ],
        ),
      ),
    );
  }
}

class _NewOrderDialog extends StatefulWidget {
  const _NewOrderDialog();

  @override
  State<_NewOrderDialog> createState() => _NewOrderDialogState();
}

class _NewOrderDialogState extends State<_NewOrderDialog> {
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _summary = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_phone, _name, _summary, _amount, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final phone = normalisePhoneDigits(_phone.text);
    final summary = _summary.text.trim();
    final amountText = _amount.text.replaceAll(',', '').trim();
    final amount = amountText.isEmpty ? null : double.tryParse(amountText);

    if (phone.length < 13) {
      setState(() => _error = 'Enter the customer\'s full phone number, for example 0802 333 4499.');
      return;
    }
    if (summary.isEmpty) {
      setState(() => _error = 'Describe the products ordered.');
      return;
    }
    if (amountText.isNotEmpty && amount == null) {
      setState(() => _error = 'The amount must be a number, for example 25000.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AdminRepository().createOrder(
        phone: phone,
        name: _name.text.trim(),
        summary: summary,
        amount: amount,
        notes: _notes.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'The order could not be saved. Check the details and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New order'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Customer phone')),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Customer name (optional)')),
            TextField(controller: _summary, maxLines: 2, decoration: const InputDecoration(labelText: 'Products ordered')),
            TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount in naira (optional)')),
            TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes (optional)')),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Color(0xFFB3261E)))),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save order')),
      ],
    );
  }
}