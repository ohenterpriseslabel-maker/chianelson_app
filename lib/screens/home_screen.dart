import 'package:flutter/material.dart';

import '../app_state.dart';
import '../brand_logo.dart';
import '../models.dart';
import '../theme.dart';
import '../whatsapp.dart';
import '../widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final best = state.bestSellers.isNotEmpty ? state.bestSellers : state.products.take(8).toList();
    final loadingFirstTime = state.loading && state.products.isEmpty;

    return SafeArea(
      child: RefreshIndicator(
        color: Brand.navy,
        onRefresh: state.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  const BrandLogo(height: 46),
                  const Spacer(),
                  IconButton.filledTonal(
                    tooltip: 'Search',
                    onPressed: () => openShop(context),
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (loadingFirstTime)
              const _LoadingHome()
            else if (state.error != null && state.products.isEmpty)
              _ErrorPanel(message: state.error!, onRetry: state.load)
            else ...[
              FadeSlideIn(index: 0, child: _Hero(banners: state.banners)),
              if (state.categories.isNotEmpty) ...[
                FadeSlideIn(index: 1, child: const SectionHeader('Shop by room')),
                FadeSlideIn(
                  index: 2,
                  child: SizedBox(
                    height: 116,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      itemCount: state.categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _RoomTile(
                        name: state.categories[i],
                        onTap: () => openShop(context, category: state.categories[i]),
                      ),
                    ),
                  ),
                ),
              ],
              if (best.isNotEmpty) ...[
                FadeSlideIn(
                  index: 3,
                  child: SectionHeader('Best sellers', actionLabel: 'See all', onAction: () => openShop(context)),
                ),
                ProductRow(best),
              ],
              if (state.newArrivals.isNotEmpty) ...[
                FadeSlideIn(index: 4, child: const SectionHeader('New arrivals')),
                ProductRow(state.newArrivals),
              ],
              FadeSlideIn(index: 5, child: const Padding(padding: EdgeInsets.fromLTRB(20, 26, 20, 0), child: _HelpCard())),
            ],
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatefulWidget {
  const _Hero({required this.banners});

  final List<HomeBanner> banners;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  late final PageController _pages = PageController(viewportFraction: 0.9)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.banners.isEmpty ? 1 : widget.banners.length;
    return SizedBox(
      height: 228,
      child: PageView.builder(
        controller: _pages,
        itemCount: count,
        itemBuilder: (_, i) {
          final page = _pages.hasClients ? (_pages.page ?? 0) : 0.0;
          final scale = (1 - (page - i).abs() * 0.07).clamp(0.92, 1.0);
          return Transform.scale(
            scale: scale,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: widget.banners.isEmpty ? const _DefaultSlide() : _BannerSlide(banner: widget.banners[i]),
            ),
          );
        },
      ),
    );
  }
}

class _DefaultSlide extends StatelessWidget {
  const _DefaultSlide();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Brand.navy, Color(0xFF34497D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Brand.gold.withValues(alpha: 0.18)),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -30,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Brand.gold.withValues(alpha: 0.12)),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 36, height: 3, color: Brand.gold),
                const SizedBox(height: 14),
                const Text(
                  'Gadgets for\na better home.',
                  style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w800, height: 1.12),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Browse, add to your cart, and order on WhatsApp.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Brand.gold,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(150, 46),
                  ),
                  onPressed: () => openShop(context),
                  child: const Text('Shop now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerSlide extends StatelessWidget {
  const _BannerSlide({required this.banner});

  final HomeBanner banner;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: () => openShop(context, category: banner.category),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (banner.imageUrl != null) ProductImage(url: banner.imageUrl!) else const ColoredBox(color: Brand.navy),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    banner.title,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  if (banner.subtitle.isNotEmpty)
                    Text(banner.subtitle, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconForRoom(String name) {
  final n = name.toLowerCase();
  if (n.contains('kitchen')) return Icons.kitchen_outlined;
  if (n.contains('bath')) return Icons.bathtub_outlined;
  if (n.contains('living')) return Icons.weekend_outlined;
  if (n.contains('bed')) return Icons.bed_outlined;
  if (n.contains('light')) return Icons.lightbulb_outline;
  if (n.contains('clean')) return Icons.cleaning_services_outlined;
  return Icons.home_outlined;
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 112,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: softShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Brand.gold.withValues(alpha: 0.14),
                ),
                child: Icon(_iconForRoom(name), color: Brand.navy),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, color: Brand.navy, height: 1.2, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Brand.whatsapp.withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.chat_bubble_outline, color: Brand.whatsapp),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Need help choosing?',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Brand.navy),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Chat with us on WhatsApp. We will confirm the price, availability and delivery with you.',
            style: TextStyle(color: Brand.muted, height: 1.45),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Brand.whatsapp),
            onPressed: () => chatOnWhatsApp(context),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Chat on WhatsApp'),
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholders while the catalogue loads.
class _LoadingHome extends StatelessWidget {
  const _LoadingHome();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Skeleton(height: 220, radius: 26)),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: const [
              Expanded(child: Skeleton(height: 150, radius: 22)),
              SizedBox(width: 14),
              Expanded(child: Skeleton(height: 150, radius: 22)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: Brand.muted),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 18),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}