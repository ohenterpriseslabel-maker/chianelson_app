import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../app_state.dart';
import '../config.dart';
import '../models.dart';
import '../repository.dart';
import '../whatsapp.dart';
import '../widgets.dart';

/// One product: photos, video, colours, specifications, reviews and the WhatsApp enquiry button.
class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.productId});
  final String productId;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _repo = Repository();
  late Future<List<Review>> _reviews = _repo.reviews(widget.productId);

  Future<void> _writeReview(Product product) async {
    final state = AppScope.of(context);
    if (!state.signedIn) {
      goToAccount(context);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<_ReviewDraft>(context: context, builder: (_) => const _ReviewDialog());
    if (result == null) return;
    try {
      await _repo.addReview(productId: product.id, author: result.name, rating: result.rating, comment: result.comment);
      messenger.showSnackBar(const SnackBar(content: Text('Thank you! Your review will appear once CHIANELSON approves it.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Your review could not be sent. Please try again.')));
    }
    if (mounted) setState(() => _reviews = _repo.reviews(product.id));
  }

  @override
  Widget build(BuildContext context) {
    final product = AppScope.of(context).productById(widget.productId);
    if (product == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('This product is no longer available.')));
    }
    final outOfStock = product.stock == StockStatus.outOfStock;

    return Scaffold(
      appBar: AppBar(actions: [Padding(padding: const EdgeInsets.only(right: 8), child: FavouriteButton(product))]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1FA855), foregroundColor: Colors.white),
            onPressed: () => enquireOnWhatsApp(context, product),
            icon: const Icon(Icons.chat),
            label: Text(outOfStock ? 'Ask when it is back in stock' : 'Enquire / Negotiate on WhatsApp'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SizedBox(
            height: 320,
            child: PageView(children: [for (final url in product.gallery) ProductImage(url: url, fit: BoxFit.contain)]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.category.toUpperCase(), style: const TextStyle(color: AppConfig.gold, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1.5)),
                const SizedBox(height: 6),
                Text(product.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                StockBadge(product.stock),
                if (product.description.isNotEmpty) ...[const SizedBox(height: 14), Text(product.description, style: const TextStyle(height: 1.5))],
                if (product.colours.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Available colours', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [for (final c in product.colours) Chip(label: Text(c), backgroundColor: Colors.white)]),
                ],
              ],
            ),
          ),
          if (product.video != null) ...[const SectionTitle('Video'), Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _ProductVideo(url: product.video!))],
          if (product.features.isNotEmpty) ...[
            const SectionTitle('Features & specifications'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < product.features.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: Text(product.features[i].label, style: const TextStyle(fontWeight: FontWeight.w600))),
                            const SizedBox(width: 12),
                            Expanded(flex: 6, child: Text(product.features[i].value, style: const TextStyle(color: Colors.black54))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SectionTitle('Reviews'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FutureBuilder<List<Review>>(
              future: _reviews,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                final reviews = snap.data ?? const <Review>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reviews.isEmpty) const Text('No reviews yet. Be the first to share your experience.', style: TextStyle(color: Colors.black54)),
                    for (final r in reviews)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                for (var s = 1; s <= 5; s++) Icon(s <= r.rating ? Icons.star : Icons.star_border, size: 18, color: AppConfig.gold),
                                const Spacer(),
                                Text(formatDate(r.createdAt), style: const TextStyle(fontSize: 12, color: Colors.black45)),
                              ]),
                              const SizedBox(height: 6),
                              Text(r.author, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (r.comment.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(r.comment)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(onPressed: () => _writeReview(product), icon: const Icon(Icons.rate_review_outlined), label: const Text('Write a review')),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewDraft {
  const _ReviewDraft(this.name, this.rating, this.comment);
  final String name;
  final int rating;
  final String comment;
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _name = TextEditingController();
  final _comment = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _name.dispose();
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Write a review'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var s = 1; s <= 5; s++)
                  IconButton(
                    tooltip: '$s star${s == 1 ? '' : 's'}',
                    onPressed: () => setState(() => _rating = s),
                    icon: Icon(s <= _rating ? Icons.star : Icons.star_border, color: AppConfig.gold),
                  ),
              ],
            ),
            TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Your name')),
            TextField(controller: _comment, maxLines: 3, decoration: const InputDecoration(labelText: 'Your review')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, _ReviewDraft(name, _rating, _comment.text.trim()));
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}

class _ProductVideo extends StatefulWidget {
  const _ProductVideo({required this.url});
  final String url;

  @override
  State<_ProductVideo> createState() => _ProductVideoState();
}

class _ProductVideoState extends State<_ProductVideo> {
  late final VideoPlayerController _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
  late final Future<void> _ready = _controller.initialize();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snap) {
        if (snap.hasError) return const SizedBox(height: 80, child: Center(child: Text('This video could not be played.')));
        if (snap.connectionState != ConnectionState.done) return const AspectRatio(aspectRatio: 16 / 9, child: Center(child: CircularProgressIndicator()));
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller,
              builder: (_, value, __) => Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller),
                  IconButton.filled(
                    tooltip: value.isPlaying ? 'Pause video' : 'Play video',
                    onPressed: () => value.isPlaying ? _controller.pause() : _controller.play(),
                    icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}