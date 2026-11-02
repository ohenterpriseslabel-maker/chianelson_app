import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'models.dart';
import 'repository.dart';

/// Everything the screens share: the catalogue, the home banners, the signed-in customer's favourites and navigation.
class AppState extends ChangeNotifier {
  AppState() {
    _auth = Supabase.instance.client.auth.onAuthStateChange.listen((_) => refreshUserData());
  }

  final repo = Repository();
  late final StreamSubscription<AuthState> _auth;

  /// The bottom tab that is open (0 Home, 1 Shop, 2 Wishlist, 3 Orders, 4 Account) and the shop's room filter.
  final selectedTab = ValueNotifier<int>(0);
  final shopCategory = ValueNotifier<String?>(null);

  List<Product> products = [];
  List<HomeBanner> banners = [];
  Set<String> wishlist = {};
  bool loading = true;
  String? error;

  bool get signedIn => Supabase.instance.client.auth.currentSession != null;

  Product? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Rooms and categories to filter by, in alphabetical order.
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
  List<Product> get wishlisted => products.where((p) => wishlist.contains(p.id)).toList();

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      products = await repo.products();
    } catch (e) {
      error = 'We could not load the catalogue.\n\n${_detail(e)}\n\n${_keyCheck()}';
    }
    // Banners and favourites are optional: a problem there must never hide the products.
    try {
      banners = await repo.banners();
    } catch (_) {
      banners = [];
    }
    await _loadWishlist();
    loading = false;
    notifyListeners();
  }

  /// Shows how the app sees the key: its length and first characters only, never the whole key.
  String _keyCheck() {
    final key = AppConfig.supabaseKey;
    final start = key.length >= 6 ? key.substring(0, 6) : key;
    return 'Key check: ${key.length} characters, starts with "$start".';
  }

  /// The first part of the real error, so it can be read and fixed.
  String _detail(Object e) {
    final text = e.toString();
    return text.length > 400 ? text.substring(0, 400) : text;
  }

  Future<void> _loadWishlist() async {
    try {
      wishlist = await repo.wishlist();
    } catch (_) {
      wishlist = {};
    }
  }

  Future<void> refreshUserData() async {
    await _loadWishlist();
    notifyListeners();
  }

  /// Returns false when the customer has to sign in first.
  Future<bool> toggleWishlist(String productId) async {
    if (!signedIn) return false;
    final on = !wishlist.contains(productId);
    wishlist = on ? {...wishlist, productId} : ({...wishlist}..remove(productId));
    notifyListeners();
    try {
      await repo.setWishlisted(productId, on);
    } catch (_) {
      wishlist = on ? ({...wishlist}..remove(productId)) : {...wishlist, productId};
      notifyListeners();
    }
    return true;
  }

  @override
  void dispose() {
    _auth.cancel();
    selectedTab.dispose();
    shopCategory.dispose();
    super.dispose();
  }
}

/// Gives every screen access to the shared [AppState].
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}