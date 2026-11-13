import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../repository.dart';
import '../theme.dart';
import '../whatsapp.dart';
import '../widgets.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _repo = Repository();
  final _page = PageController();
  int _photo = 0;
  String? _colour;
  int _quantity = 1;
  late Future<List<Review>> _reviews = _repo.reviews(widget.productId);

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _addToCart(Product p) {
    if (p.colours.isNotEmpty && _colour == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a colour first.')));
      return;
    }
    final state = AppScope.of(context);
    final navigator = Navigator.of(context);
    state.cart.add(p.id, colour: _colour, quantity: _quantity);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text('${p.name} added to your cart'),
      action: SnackBarAction(
        label: 'View cart',
        onPressed: () {
          navigator.popUntil((r) => r.isFirst);
          state.selectedTab.value = 2;
        },
      ),
    ));
  }

  Future<void> _writeReview(Product p) async {
    final draft = await showDialog<_ReviewDraft>(context: context, builder: (_) => const _ReviewDialog());
    if (draft == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.addReview(
        productId: p.id,
        author: draft.name,
        rating: draft.rating,
        comment: draft.comment,
      );
      messenger.showSnackBar(const SnackBar(
        content: Text('Thank you! Your review will appear once CHIANELSON approves it.'),
      ));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Your review could not be sent. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = state.productById(widget.productId);
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off,
          title: 'Not available',
          message: 'This product is no longer in the catalogue.',
        ),
      );
    }

    final total = p.price == null ? null : p.price! * _quantity;

    return Scaffold(
      appBar: AppBar(title: Text(p.category)),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Brand.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total', style: TextStyle(color: Brand.muted, fontSize: 12)),
                    Text(
                      total == null ? 'On request' : ngn(total),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Brand.navy),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 190,
                child: FilledButton.icon(
                  onPressed: p.inStock ? () => _addToCart(p) : null,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text(p.inStock ? 'Add to cart' : 'Out of stock'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SizedBox(
            height: 340,
            child: Stack(
              children: [
                Container(
                  color: Colors.white,
                  child: PageView.builder(
                    controller: _page,
                    itemCount: p.gallery.length,
                    onPageChanged: (i) => setState(() => _photo = i),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.all(20),
                      child: i == 0
                          ? Hero(tag: heroTagFor(p), child: ProductImage(url: p.gallery[i], fit: BoxFit.contain))
                          : ProductImage(url: p.gallery[i], fit: BoxFit.contain),
                    ),
                  ),
                ),
                if (p.gallery.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < p.gallery.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _photo ? 18 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == _photo ? Brand.navy : Brand.line,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.2, color: Brand.ink)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    PriceText(p, size: 22),
                    const Spacer(),
                    StockBadge(p.stock),
                  ],
                ),
                if (p.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(p.description, style: const TextStyle(height: 1.5, color: Brand.ink)),
                ],
                if (p.colours.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const _Label('Colour'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final c in p.colours)
                        ChoiceChip(
                          label: Text(c),
                          selected: _colour == c,
                          onSelected: (_) => setState(() => _colour = c),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    const _Label('Quantity'),
                    const Spacer(),
                    QuantityStepper(value: _quantity, onChanged: (q) => setState(() => _quantity = q)),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => enquireOnWhatsApp(context, p, colour: _colour),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Ask about this on WhatsApp'),
                ),
              ],
            ),
          ),
          if (p.features.isNotEmpty) ...[
            const _SectionTitle('Features & specifications'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                child: Column(
                  children: [
                    for (var i = 0; i < p.features.length; i++) ...[
                      if (i > 0) const Divider(height: 1, color: Brand.line),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(p.features[i].label,
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: Brand.navy)),
                            ),
                            Expanded(
                              flex: 6,
                              child: Text(p.features[i].value, style: const TextStyle(color: Brand.ink)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const _SectionTitle('Customer reviews'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FutureBuilder<List<Review>>(
              future: _reviews,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
                }
                final reviews = snap.data ?? const <Review>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (reviews.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text('No reviews yet. Be the first to share your experience.',
                            style: TextStyle(color: Brand.muted)),
                      ),
                    for (final r in reviews)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                for (var s = 1; s <= 5; s++)
                                  Icon(s <= r.rating ? Icons.star : Icons.star_border, size: 18, color: Brand.gold),
                                const Spacer(),
                                Text(formatDate(r.createdAt), style: const TextStyle(fontSize: 12, color: Brand.muted)),
                              ]),
                              const SizedBox(height: 8),
                              Text(r.author, style: const TextStyle(fontWeight: FontWeight.w700)),
                              if (r.comment.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(r.comment, style: const TextStyle(height: 1.4)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _writeReview(p),
                      icon: const Icon(Icons.rate_review_outlined),
                      label: const Text('Write a review'),
                    ),
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

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Brand.navy));
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
        child: Text(text, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Brand.navy)),
      );
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
  String? _error;

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
                    icon: Icon(s <= _rating ? Icons.star : Icons.star_border, color: Brand.gold),
                  ),
              ],
            ),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Your name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _comment,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Your review'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!, style: const TextStyle(color: Brand.danger)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) {
              setState(() => _error = 'Please enter your name.');
              return;
            }
            Navigator.pop(context, _ReviewDraft(name, _rating, _comment.text.trim()));
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}