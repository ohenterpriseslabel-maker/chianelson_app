import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _search = TextEditingController();
  bool _inStockOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return SafeArea(
      child: ValueListenableBuilder<String?>(
        valueListenable: state.shopCategory,
        builder: (context, category, _) {
          final needle = _search.text.trim().toLowerCase();
          final results = state.products.where((p) {
            final inRoom = category == null || p.rooms.contains(category) || p.category == category;
            final matches = needle.isEmpty ||
                p.name.toLowerCase().contains(needle) ||
                p.category.toLowerCase().contains(needle);
            return inRoom && matches && (!_inStockOnly || p.inStock);
          }).toList();

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Text('Shop',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Brand.navy)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search gadgets',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(_search.clear),
                            ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    children: [
                      for (final name in ['All', ...state.categories])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(name),
                            selected: name == 'All' ? category == null : category == name,
                            onSelected: (_) {
                              state.shopCategory.value = name == 'All' ? null : name;
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Row(
                    children: [
                      Text(
                        '${results.length} ${results.length == 1 ? 'product' : 'products'}',
                        style: const TextStyle(color: Brand.muted, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      FilterChip(
                        label: const Text('In stock only'),
                        selected: _inStockOnly,
                        onSelected: (v) => setState(() => _inStockOnly = v),
                      ),
                    ],
                  ),
                ),
              ),
              if (state.loading && state.products.isEmpty)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (results.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: 'No products found',
                    message: 'Try another word, or choose a different room.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.62,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => ProductCard(results[i]),
                      childCount: results.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}