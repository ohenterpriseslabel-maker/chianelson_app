import 'package:flutter/material.dart';

import '../admin_repository.dart';

const _stockLabels = {
  'in_stock': 'In stock',
  'low_stock': 'Low stock',
  'out_of_stock': 'Out of stock',
};

/// Set each product to in stock, low stock or out of stock. The shop shows this to customers.
class AdminStockScreen extends StatefulWidget {
  const AdminStockScreen({super.key});

  @override
  State<AdminStockScreen> createState() => _AdminStockScreenState();
}

class _AdminStockScreenState extends State<AdminStockScreen> {
  final _repo = AdminRepository();
  late Future<List<AdminProductStock>> _items = _repo.productStock();

  void _reload() {
    setState(() => _items = _repo.productStock());
  }

  Future<void> _set(AdminProductStock product, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.setStockStatus(product.id, status);
      if (mounted) _reload();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Stock could not be updated. Try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock status')),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _items;
        },
        child: FutureBuilder<List<AdminProductStock>>(
          future: _items,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return const Center(child: Text('Products could not be loaded. Pull down to try again.'));
            final items = snap.data ?? const <AdminProductStock>[];
            if (items.isEmpty) return const Center(child: Text('No products yet.'));
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = items[i];
                final current = _stockLabels.containsKey(p.status) ? p.status : 'in_stock';
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    title: Text(p.name),
                    trailing: DropdownButton<String>(
                      value: current,
                      underline: const SizedBox.shrink(),
                      items: [for (final e in _stockLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                      onChanged: (v) {
                        if (v != null && v != current) _set(p, v);
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}