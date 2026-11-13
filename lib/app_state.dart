import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cart.dart';
import 'models.dart';
import 'repository.dart';

/// What every screen shares: the catalogue, the banners, the cart and navigation.
class AppState extends ChangeNotifier {
  AppState() {
    cart.load();
  }

  final repo = Repository();
  final cart = CartStore();

  /// The open tab (0 Home, 1 Shop, 2 Cart, 3 More) and the shop's room filter.
  final selectedTab = ValueNotifier<int>(0);
  final shopCategory = ValueNotifier<String?>(null);

  List<Product> products = [];
  List<HomeBanner> banners = [];
  bool loading = true;
  String? error;

  Product? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Rooms and categories to browse by, in alphabetical order.
  List<String> get categories {
    final set = <String>{};
    for (final p in products) {
      set.addAll(p.rooms);
      if (p.category.isNotEmpty) set.add(p.category);
    }
    return set.toList()..sort();
  }

  List<Product> get bestSellers => products.where((p) => p.featured).toList();

  /// The eight most recently added products.
  List<Product> get newArrivals => ([...products]..sort((a, b) => b.createdAt.compareTo(a.createdAt))).take(8).toList();

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      products = await repo.products();
    } catch (e) {
      error = 'We could not load the catalogue.\n\n${_detail(e)}';
    }
    // Banners are optional: a problem there must never hide the products.
    try {
      banners = await repo.banners();
    } catch (_) {
      banners = [];
    }
    loading = false;
    notifyListeners();
  }

  String _detail(Object e) {
    final text = e.toString();
    return text.length > 300 ? text.substring(0, 300) : text;
  }

  @override
  void dispose() {
    selectedTab.dispose();
    shopCategory.dispose();
    cart.dispose();
    super.dispose();
  }
}

/// Gives every screen access to the shared [AppState].
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}