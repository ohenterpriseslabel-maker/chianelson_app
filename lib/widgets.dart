import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'app_state.dart';
import 'config.dart';
import 'models.dart';
import 'screens/product_screen.dart';

/// Leaves any open product page and shows the Account tab.
void goToAccount(BuildContext context) {
  final state = AppScope.of(context);
  Navigator.of(context).popUntil((route) => route.isFirst);
  state.selectedTab.value = 4;
}

/// Leaves any open product page and shows the Shop tab, optionally filtered to one room or category.
void openShop(BuildContext context, {String? category}) {
  final state = AppScope.of(context);
  Navigator.of(context).popUntil((route) => route.isFirst);
  state.shopCategory.value = category;
  state.selectedTab.value = 1;
}

void openProduct(BuildContext context, Product product) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ProductScreen(productId: product.id)));
}

/// Saves or removes a favourite, or sends the customer to sign in first.
Future<void> toggleFavourite(BuildContext context, Product product) async {
  final state = AppScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final ok = await state.toggleWishlist(product.id);
  if (!ok) {
    messenger.showSnackBar(SnackBar(
      content: const Text('Sign in to save favourites.'),
      action: SnackBarAction(label: 'Sign in', onPressed: () => state.selectedTab.value = 4),
    ));
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
      placeholder: (_, __) => const ColoredBox(color: Color(0xFFF1ECDF)),
      errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFFF1ECDF), child: Center(child: Icon(Icons.image_outlined, color: Colors.black26, size: 36))),
    );
  }
}

class StockBadge extends StatelessWidget {
  const StockBadge(this.stock, {super.key});
  final StockStatus stock;

  @override
  Widget build(BuildContext context) {
    final colour = switch (stock) {
      StockStatus.inStock => const Color(0xFF2E7D4F),
      StockStatus.lowStock => const Color(0xFFB7791F),
      StockStatus.outOfStock => const Color(0xFFB3261E),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: colour.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(stock.label, style: TextStyle(color: colour, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class FavouriteButton extends StatelessWidget {
  const FavouriteButton(this.product, {super.key});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final saved = AppScope.of(context).wishlist.contains(product.id);
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => toggleFavourite(context, product),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(saved ? Icons.favorite : Icons.favorite_border, size: 20, color: saved ? const Color(0xFFB3261E) : AppConfig.navy),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard(this.product, {super.key});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => openProduct(context, product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(url: product.coverUrl),
                  Positioned(top: 6, right: 6, child: FavouriteButton(product)),
                  if (product.stock == StockStatus.outOfStock) Positioned(left: 6, bottom: 6, child: StockBadge(product.stock)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.25)),
                  const SizedBox(height: 4),
                  Text(product.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A two-column grid of products.
class ProductGrid extends StatelessWidget {
  const ProductGrid(this.products, {super.key});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72),
      itemCount: products.length,
      itemBuilder: (_, i) => ProductCard(products[i]),
    );
  }
}

/// Shown on tabs that need a signed-in customer.
class NeedsSignIn extends StatelessWidget {
  const NeedsSignIn({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppConfig.gold),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.4)),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => AppScope.of(context).selectedTab.value = 4, child: const Text('Sign in with your phone')),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.fromLTRB(16, 24, 16, 12), child: Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)));
}