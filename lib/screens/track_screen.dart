import 'package:flutter/material.dart';

import '../models.dart';
import '../repository.dart';
import '../theme.dart';

/// Lets a customer check an order with their phone number and the reference CHIANELSON sent them.
class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  final _repo = Repository();
  final _phone = TextEditingController();
  final _reference = TextEditingController();
  bool _busy = false;
  String? _error;
  TrackedOrder? _order;

  @override
  void dispose() {
    _phone.dispose();
    _reference.dispose();
    super.dispose();
  }

  /// 0802 333 4499 becomes 2348023334499.
  String _digits(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.startsWith('0') ? '234${digits.substring(1)}' : digits;
  }

  Future<void> _track() async {
    final phone = _digits(_phone.text);
    final reference = _reference.text.trim();
    if (phone.length < 13) {
      setState(() => _error = 'Enter the phone number you ordered with, for example 0802 333 4499.');
      return;
    }
    if (reference.isEmpty) {
      setState(() => _error = 'Enter the order reference CHIANELSON sent you, for example CH-4F9A2C.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _order = null;
    });
    try {
      final order = await _repo.trackOrder(phone, reference);
      if (mounted) setState(() => _order = order);
    } on TrackingException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track your order')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Enter the phone number you ordered with, and the order reference we sent you on WhatsApp.',
            style: TextStyle(color: Brand.muted, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone number', hintText: '0802 333 4499'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reference,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Order reference', hintText: 'CH-4F9A2C'),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(_error!, style: const TextStyle(color: Brand.danger, height: 1.4)),
            ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _track,
            child: Text(_busy ? 'Checking…' : 'Track order'),
          ),
          if (_order != null) ...[
            const SizedBox(height: 24),
            _OrderCard(order: _order!),
          ],
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final TrackedOrder order;

  @override
  Widget build(BuildContext context) {
    final current = orderSteps.indexOf(order.status).clamp(0, orderSteps.length - 1);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(order.reference,
                      style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1, color: Brand.navy)),
                ),
                Text(formatDate(order.createdAt), style: const TextStyle(color: Brand.muted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(order.summary, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 20),
            for (var i = 0; i < orderSteps.length; i++)
              _Step(
                label: orderStepLabel(orderSteps[i]),
                done: i <= current,
                current: i == current,
                last: i == orderSteps.length - 1,
              ),
            const SizedBox(height: 8),
            Text('Last updated ${formatDate(order.updatedAt)}',
                style: const TextStyle(color: Brand.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.done, required this.current, required this.last});

  final String label;
  final bool done;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colour = done ? Brand.navy : Brand.line;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? Brand.navy : Colors.white,
                  border: Border.all(color: colour, width: 2),
                ),
                child: done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
              if (!last) Expanded(child: Container(width: 2, color: colour)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: current ? FontWeight.w800 : FontWeight.w500,
                  color: done ? Brand.navy : Brand.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}