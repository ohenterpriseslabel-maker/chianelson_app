import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'models.dart';

class _Media {
  final List<String> images = [];
}

/// A tracking problem the customer can read, such as a wrong reference.
class TrackingException implements Exception {
  TrackingException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Everything customers read and write. No sign-in is needed.
class Repository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<Product>> products() async {
    final rows = await _db.from('products').select().order('sort_order').order('created_at');
    final media = await _media();
    return rows.map((r) {
      final m = media[r['id'] as String];
      return Product.fromRow(r, images: m?.images ?? const []);
    }).toList();
  }

  /// Photos for every product, as links that work for a few hours.
  Future<Map<String, _Media>> _media() async {
    final rows = await _db
        .from('product_images')
        .select('product_id,storage_path,kind')
        .order('created_at', ascending: false);
    if (rows.isEmpty) return {};
    final urls = await _sign(rows.map((r) => r['storage_path'] as String).toList());
    final byProduct = <String, _Media>{};
    for (final r in rows) {
      if (r['kind'] == 'video') continue;
      final url = urls[r['storage_path']];
      if (url == null) continue;
      byProduct.putIfAbsent(r['product_id'] as String, _Media.new).images.add(url);
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

  /// Only approved reviews are shown.
  Future<List<Review>> reviews(String productId) async {
    final rows = await _db
        .from('reviews')
        .select()
        .eq('product_id', productId)
        .eq('approved', true)
        .order('created_at', ascending: false);
    return rows.map(Review.fromRow).toList();
  }

  /// A review waits for approval before it appears.
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

  /// Finds an order by the customer's phone number and the reference CHIANELSON sent them.
  Future<TrackedOrder> trackOrder(String phone, String reference) async {
    final result = await _db.rpc('track_order', params: {
      '_phone': phone,
      '_reference': reference,
    });
    final map = Map<String, dynamic>.from(result as Map);
    if (map['ok'] != true) {
      throw TrackingException(map['message'] as String? ?? 'We could not find that order.');
    }
    return TrackedOrder.fromJson(map);
  }
}