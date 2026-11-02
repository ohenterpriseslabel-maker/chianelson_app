import 'package:flutter/material.dart';

import '../admin_repository.dart';
import '../config.dart';
import 'admin_banners_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_rewards_screen.dart';
import 'admin_stock_screen.dart';
import 'admin_reviews_screen.dart';

/// Shows the admin dashboard link on the Account tab, but only to accounts with the admin role.
class AdminEntry extends StatefulWidget {
  const AdminEntry({super.key});

  @override
  State<AdminEntry> createState() => _AdminEntryState();
}

class _AdminEntryState extends State<AdminEntry> {
  late final Future<bool> _isAdmin = AdminRepository().isAdmin();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin,
      builder: (context, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined, color: AppConfig.navy),
              title: const Text('Admin dashboard'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AdminScreen())),
            ),
          ),
        );
      },
    );
  }
}

/// The admin dashboard: a sales summary and links to each admin area.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _repo = AdminRepository();
  late Future<List<AdminOrder>> _orders = _repo.orders();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _orders = _repo.orders());
          await _orders;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<List<AdminOrder>>(
              future: _orders,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Card(margin: EdgeInsets.zero, child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())));
                }
                if (snap.hasError) {
                  return const Card(margin: EdgeInsets.zero, child: Padding(padding: EdgeInsets.all(16), child: Text('Sales could not be loaded. Pull down to try again.')));
                }
                return _SalesCard(snap.data ?? const []);
              },
            ),
            const SizedBox(height: 16),
            const _Tile(
              icon: Icons.local_shipping_outlined,
              title: 'Orders and tracking',
              subtitle: 'Create orders and move them through each stage',
              page: AdminOrdersScreen(),
            ),
            const _Tile(
              icon: Icons.view_carousel_outlined,
              title: 'Home banners',
              subtitle: 'Add, hide or remove the banners on the home page',
              page: AdminBannersScreen(),
            ),
            const _Tile(
              icon: Icons.rate_review_outlined,
              title: 'Review approval',
              subtitle: 'Approve or remove customer reviews',
              page: AdminReviewsScreen(),
            ),
            const _Tile(
              icon: Icons.card_giftcard_outlined,
              title: 'Referral rewards',
              subtitle: 'Record rewards for customers who referred friends',
              page: AdminRewardsScreen(),
            ),
            const _Tile(
              icon: Icons.inventory_2_outlined,
              title: 'Stock status',
              subtitle: 'Mark each product in stock, low stock or out of stock',
              page: AdminStockScreen(),
            ),
            const _Tile(
              icon: Icons.notifications_outlined,
              title: 'Push notifications',
              subtitle: 'Coming soon: needs the Firebase setup',
              page: null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.page});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? page;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: page == null ? Colors.black38 : AppConfig.navy),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: page == null ? null : const Icon(Icons.chevron_right),
        enabled: page != null,
        onTap: page == null ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page!)),
      ),
    );
  }
}

class _SalesCard extends StatelessWidget {
  const _SalesCard(this.orders);
  final List<AdminOrder> orders;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final recent = orders.where((o) => now.difference(o.createdAt).inDays < 30).toList();
    final delivered = orders.where((o) => o.status == 'delivered').toList();
    final inProgress = orders.length - delivered.length;

    double total(List<AdminOrder> list) => list.fold<double>(0, (sum, o) => sum + (o.amount ?? 0));

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sales', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                _Stat(label: 'Last 30 days', value: naira(total(recent)), detail: '${recent.length} orders'),
                _Stat(label: 'Delivered', value: naira(total(delivered)), detail: '${delivered.length} orders'),
              ],
            ),
            const SizedBox(height: 12),
            Text('$inProgress in progress · ${orders.length} in total', style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.detail});
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          Text(detail, style: const TextStyle(color: Colors.black45, fontSize: 12)),
        ],
      ),
    );
  }
}