import 'package:flutter/material.dart';

import '../app_state.dart';
import '../config.dart';
import '../brand_logo.dart';
import '../models.dart';
import '../widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final bestSellers = state.bestSellers.isNotEmpty ? state.bestSellers : state.products.take(6).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: state.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  const Expanded(child: Align(alignment: Alignment.centerLeft, child: BrandLogo(height: 44))),
                  IconButton(tooltip: 'Search products', icon: const Icon(Icons.search), onPressed: () => openShop(context)),
                ],
              ),
            ),
            if (state.loading && state.products.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator()))
            else if (state.error != null && state.products.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(children: [
                  Text(state.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: state.load, child: const Text('Try again')),
                ]),
              )
            else ...[
              const SizedBox(height: 12),
              _Banners(state.banners),
              const SectionTitle('Shop by room'),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ActionChip(label: Text(state.categories[i]), onPressed: () => openShop(context, category: state.categories[i])),
                ),
              ),
              if (bestSellers.isNotEmpty) ...[const SectionTitle('Best sellers'), _ProductRow(bestSellers)],
              if (state.newArrivals.isNotEmpty) ...[const SectionTitle('New arrivals'), _ProductRow(state.newArrivals)],
              const SizedBox(height: 16),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: OutlinedButton(onPressed: () => openShop(context), child: const Text('See the full collection'))),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow(this.products);
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 270,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => SizedBox(width: 165, child: ProductCard(products[i])),
      ),
    );
  }
}

class _Banners extends StatelessWidget {
  const _Banners(this.banners);
  final List<HomeBanner> banners;

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppConfig.navy, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gadgets for a better home.', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700, height: 1.2)),
              const SizedBox(height: 8),
              const Text('Browse, then enquire and negotiate on WhatsApp.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppConfig.gold, minimumSize: const Size(160, 44)),
                onPressed: () => openShop(context),
                child: const Text('Browse the collection'),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 190,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.92),
        itemCount: banners.length,
        itemBuilder: (_, i) {
          final b = banners[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => openShop(context, category: b.category),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (b.imageUrl != null) ProductImage(url: b.imageUrl!) else const ColoredBox(color: AppConfig.navy),
                    const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.center, colors: [Colors.black54, Colors.transparent]))),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(b.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                          if (b.subtitle.isNotEmpty) Text(b.subtitle, style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}