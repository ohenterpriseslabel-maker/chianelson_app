import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'models.dart';

class _Media {
  final List<String> images = [];
  String? video;
}

/// Every read and write the app makes. It talks to the same Supabase backend as the website.
class Repository {
  SupabaseClient get _db => Supabase.instance.client;
  String? get userId => _db.auth.currentUser?.id;
  /// The customer's phone number (digits only), set on the server when the account was created.
  String? get userPhone => _db.auth.currentUser?.appMetadata['phone'] as String?;

  // ---- Catalogue -------------------------------------------------------------------------------

  Future<List<Product>> products() async {
    final rows = await _db.from('products').select().order('sort_order').order('created_at');
    final media = await _media();
    return rows.map((r) {
      final m = media[r['id'] as String];
      return Product.fromRow(r, images: m?.images ?? const [], video: m?.video);
    }).toList();
  }

  /// Photos and videos for every product, as links that work for a few hours.
  Future<Map<String, _Media>> _media() async {
    final rows = await _db
        .from('product_images')
        .select('product_id,storage_path,kind')
        .order('created_at', ascending: false);
    if (rows.isEmpty) return {};
    final urls = await _sign(rows.map((r) => r['storage_path'] as String).toList());
    final byProduct = <String, _Media>{};
    for (final r in rows) {
      final url = urls[r['storage_path']];
      if (url == null) continue;
      final media = byProduct.putIfAbsent(r['product_id'] as String, _Media.new);
      if (r['kind'] == 'video') {
        media.video ??= url;
      } else {
        media.images.add(url);
      }
    }
    return byProduct;
  }

  Future<Map<String, String>> _sign(List<String> paths) async {
    if (paths.isEmpty) return {};
    final signed = await _db.storage.from(AppConfig.mediaBucket).createSignedUrls(paths, 6 * 3600);
    return {for (final s in signed) if (s.signedUrl.isNotEmpty) s.path: s.signedUrl};
  }

  Future<List<HomeBanner>> banners() async {
    final rows = await _db.from('banners').select().eq('active', true).order('sort_order');
    if (rows.isEmpty) return [];
    final urls = await _sign(rows.map((r) => r['image_path'] as String).toList());
    return rows
        .map((r) => HomeBanner(
              title: r['title'] as String? ?? '',
              subtitle: r['subtitle'] as String? ?? '',
              imageUrl: urls[r['image_path']],
              category: r['category'] as String?,
            ))
        .toList();
  }

  // ---- Wishlist --------------------------------------------------------------------------------

  Future<Set<String>> wishlist() async {
    if (userId == null) return {};
    final rows = await _db.from('wishlist_items').select('product_id');
    return rows.map((r) => r['product_id'] as String).toSet();
  }

  Future<void> setWishlisted(String productId, bool on) async {
    if (on) {
      await _db.from('wishlist_items').upsert({'product_id': productId}, ignoreDuplicates: true);
    } else {
      await _db.from('wishlist_items').delete().eq('product_id', productId);
    }
  }

  // ---- Reviews ---------------------------------------------------------------------------------

  /// Only reviews the owner has approved are visible.
  Future<List<Review>> reviews(String productId) async {
    final rows = await _db
        .from('reviews')
        .select()
        .eq('product_id', productId)
        .eq('approved', true)
        .order('created_at', ascending: false);
    return rows.map(Review.fromRow).toList();
  }

  Future<void> addReview({
    required String productId,
    required String author,
    required int rating,
    required String comment,
  }) async {
    await _db.from('reviews').insert({
      'product_id': productId,
      'author_name': author,
      'rating': rating,
      'comment': comment,
    });
  }

  // ---- Orders ----------------------------------------------------------------------------------

  /// Orders are created by CHIANELSON once payment is confirmed on WhatsApp; customers see theirs by phone number.
  Future<List<Order>> orders() async {
    if (userId == null) return [];
    final rows = await _db.from('orders').select().order('created_at', ascending: false);
    return rows.map(Order.fromRow).toList();
  }

  // ---- Referrals -------------------------------------------------------------------------------

  Future<ReferralSummary> referral() async {
    final data = await _db.rpc('my_referral');
    return ReferralSummary.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<bool> applyReferral(String code) async {
    final ok = await _db.rpc('apply_referral', params: {'code': code});
    return ok == true;
  }

  // ---- Sign in and sign up ---------------------------------------------------------------------

  /// The login address for a phone number. Digits only, e.g. 2348023334499@customers.chianelson.com.
  /// No email is sent: the address is only a username.
  String _emailFor(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return '$digits@customers.chianelson.com';
  }

  /// Creates an account with a phone number and password. Nothing is sent to the customer.
  Future<void> signUp(String phone, String password) async {
    await _db.auth.signUp(email: _emailFor(phone), password: password);
  }

  /// Signs in with a phone number and password.
  Future<void> signIn(String phone, String password) async {
    await _db.auth.signInWithPassword(email: _emailFor(phone), password: password);
  }

  Future<void> signOut() => _db.auth.signOut();
}