import 'package:flutter/material.dart';

import '../admin_repository.dart';
import '../app_state.dart';

/// Customer reviews wait here until approved. Only approved reviews appear on product pages.
class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  final _repo = AdminRepository();
  late Future<List<AdminReview>> _reviews = _repo.pendingReviews();

  void _reload() {
    setState(() => _reviews = _repo.pendingReviews());
  }

  Future<void> _act(Future<void> Function() action, String failure) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      if (mounted) _reload();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failure)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Review approval')),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _reviews;
        },
        child: FutureBuilder<List<AdminReview>>(
          future: _reviews,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return const Center(child: Text('Reviews could not be loaded. Pull down to try again.'));
            final reviews = snap.data ?? const <AdminReview>[];
            if (reviews.isEmpty) {
              return ListView(children: const [Padding(padding: EdgeInsets.all(32), child: Text('No reviews waiting for approval.', textAlign: TextAlign.center))]);
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                for (final r in reviews)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.productById(r.productId)?.name ?? r.productId, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Row(children: [
                            for (var s = 1; s <= 5; s++) Icon(s <= r.rating ? Icons.star : Icons.star_border, size: 16, color: const Color(0xFFB8964A)),
                            const SizedBox(width: 8),
                            Text(r.author, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ]),
                          if (r.comment.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(r.comment)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _act(() => _repo.deleteReview(r.id), 'The review could not be removed.'),
                                child: const Text('Remove'),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () => _act(() => _repo.approveReview(r.id), 'The review could not be approved.'),
                                child: const Text('Approve'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}