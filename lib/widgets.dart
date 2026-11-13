import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';
import 'screens/product_screen.dart';
import 'theme.dart';

/// The tag that links a product's photo on the card to the same photo on its page.
String heroTagFor(Product product) => 'product-image-${product.id}';

void openProduct(BuildContext context, Product product) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ProductScreen(productId: product.id)));
}

/// Shows the Shop tab, optionally filtered to one room or category.
void openShop(BuildContext context, {String? category}) {
  final state = AppScope.of(context);
  Navigator.of(context).popUntil((route) => route.isFirst);
  state.shopCategory.value = category;
  state.selectedTab.value = 1;
}

/// Shows the Cart tab.
void openCart(BuildContext context) {
  final state = AppScope.of(context);
  Navigator.of(context).popUntil((route) => route.isFirst);
  state.selectedTab.value = 2;
}

/// Fades and rises into place, a little after the item before it.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 80 + widget.index * 90), () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _shown ? Offset.zero : const Offset(0, 0.06),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// A soft, moving placeholder shown while content loads.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.height, this.width, this.radius = 16});

  final double? height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xFFEDE6D6), const Color(0xFFF8F4EA), _controller.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 350),
      placeholder: (_, __) => const Skeleton(radius: 0),
      errorWidget: (_, __, ___) => const ColoredBox(
        color: photoBackdrop,
        child: Center(child: Icon(Icons.image_outlined, color: Colors.black26, size: 36)),
      ),
    );
  }
}

class StockBadge extends StatelessWidget {
  const StockBadge(this.stock, {super.key});

  final StockStatus stock;

  @override
  Widget build(BuildContext context) {
    final colour = switch (stock) {
      StockStatus.inStock => Brand.success,
      StockStatus.lowStock => const Color(0xFFB7791F),
      StockStatus.outOfStock => Brand.danger,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: colour.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: colour),
          const SizedBox(width: 6),
          Text(stock.label, style: TextStyle(color: colour, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class PriceText extends StatelessWidget {
  const PriceText(this.product, {super.key, this.size = 16});

  final Product product;
  final double size;

  @override
  Widget build(BuildContext context) {
    final price = product.price;
    return Text(
      price == null ? 'Price on request' : ngn(price),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: price == null ? Brand.muted : Brand.navy,
        fontWeight: FontWeight.w800,
        fontSize: size,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.colour);

  final String text;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: colour, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

/// A product tile: photo on a warm backdrop, gold tags, and a clear price.
class ProductCard extends StatelessWidget {
  const ProductCard(this.product, {super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: () => openProduct(context, product),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.05,
                  child: ColoredBox(
                    color: photoBackdrop,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Hero(
                            tag: heroTagFor(product),
                            child: ProductImage(url: product.coverUrl, fit: BoxFit.contain),
                          ),
                        ),
                        if (product.featured) const Positioned(top: 10, left: 10, child: _Pill('Best seller', Brand.gold)),
                        if (!product.inStock)
                          Positioned(top: 10, right: 10, child: _Pill(product.stock.label, Brand.navy)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.category.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w800,
                                color: Brand.gold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                                color: Brand.ink,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(child: PriceText(product, size: 16)),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(color: Brand.navy, shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of products that scrolls sideways.
class ProductRow extends StatelessWidget {
  const ProductRow(this.products, {super.key});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 318,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => SizedBox(
          width: 178,
          child: FadeSlideIn(index: i, child: ProductCard(products[i])),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 12, 14),
      child: Row(
        children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: Brand.gold, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Brand.navy, letterSpacing: -0.3),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Brand.gold.withValues(alpha: 0.25), Brand.gold.withValues(alpha: 0.08)],
                ),
              ),
              child: Icon(icon, size: 38, color: Brand.gold),
            ),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Brand.navy)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Brand.muted, height: 1.45)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small − quantity + control.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({super.key, required this.value, required this.onChanged, this.max = 99});

  final int value;
  final ValueChanged<int> onChanged;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Brand.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Less',
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 30,
            child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          IconButton(
            tooltip: 'More',
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}