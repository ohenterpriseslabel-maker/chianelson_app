import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets.dart';

/// Search and filter the whole collection.
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
            final inCategory = category == null || p.category == category || p.rooms.contains(category);
            final matches = needle.isEmpty || p.name.toLowerCase().contains(needle) || p.category.toLowerCase().contains(needle);
            final available = !_inStockOnly || p.stock != StockStatus.outOfStock;
            return inCategory && matches && available;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search products',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty ? null : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(_search.clear)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final name in ['All', ...state.categories])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(name),
                          selected: name == 'All' ? category == null : category == name,
                          onSelected: (_) => state.shopCategory.value = name == 'All' ? null : name,
                        ),
                      ),
                  ],
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show only products in stock'),
                value: _inStockOnly,
                onChanged: (v) => setState(() => _inStockOnly = v),
              ),
              Text('${results.length} ${results.length == 1 ? 'product' : 'products'}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 12),
              if (state.loading && state.products.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else if (results.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No matching products. Try another search or room.')))
              else
                ProductGrid(results),
            ],
          );
        },
      ),
    );
  }
}