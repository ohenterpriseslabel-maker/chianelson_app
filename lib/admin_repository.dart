import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';

/// Turns 0802 333 4499 into 2348023334499: the digits-only form the database matches against.
String normalisePhoneDigits(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0')) digits = '234${digits.substring(1)}';
  return digits;
}

/// Formats an amount as ₦1,250,000.
String naira(double value) {
  final digits = value.round().toString();
  final grouped = digits.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  return '₦$grouped';
}

class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.reference,
    required this.customerName,
    required this.customerPhone,
    required this.summary,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String reference;
  final String customerName;
  final String customerPhone;
  final String summary;
  final double? amount;
  final String status;
  final DateTime createdAt;
}

class AdminBanner {
  const AdminBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.imageUrl,
    required this.category,
    required this.active,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imagePath;
  final String? imageUrl;
  final String? category;
  final bool active;
}

class AdminReview {
  const AdminReview({
    required this.id,
    required this.productId,
    required this.author,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String author;
  final int rating;
  final String comment;
  final DateTime createdAt;
}

class AdminReward {
  const AdminReward({
    required this.id,
    required this.referrerId,
    required this.reward,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String referrerId;
  final String reward;
  final String status;
  final DateTime createdAt;
}

class AdminProductStock {
  const AdminProductStock({required this.id, required this.name, required this.status});

  final String id;
  final String name;
  final String status;
}

/// Every read and write the admin screens make. The database only allows these for accounts with the admin role.
class AdminRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<bool> isAdmin() async {
    if (_db.auth.currentUser == null) return false;
    try {
      return (await _db.rpc('am_i_admin')) == true;
    } catch (_) {
      return false;
    }
  }

  // ---- Orders ----------------------------------------------------------------------------------

  Future<List<AdminOrder>> orders() async {
    final rows = await _db.from('orders').select().order('created_at', ascending: false);
    return rows.map(_order).toList();
  }

  static AdminOrder _order(Map<String, dynamic> r) => AdminOrder(
        id: r['id'] as String,
        reference: r['reference'] as String? ?? '',
        customerName: r['customer_name'] as String? ?? '',
        customerPhone: r['customer_phone'] as String? ?? '',
        summary: r['product_summary'] as String? ?? '',
        amount: (r['amount_ngn'] as num?)?.toDouble(),
        status: r['status'] as String? ?? 'ordered',
        createdAt: DateTime.tryParse('${r['created_at']}')?.toLocal() ?? DateTime.now(),
      );

  Future<void> createOrder({
    required String phone,
    required String name,
    required String summary,
    double? amount,
    String notes = '',
  }) async {
    await _db.from('orders').insert({
      'customer_phone': normalisePhoneDigits(phone),
      'customer_name': name,
      'product_summary': summary,
      'amount_ngn': amount,
      'notes': notes,
    });
  }

  Future<void> setOrderStatus(String id, String status) async {
    await _db.from('orders').update({'status': status}).eq('id', id);
  }

  // ---- Banners ---------------------------------------------------------------------------------

  Future<List<AdminBanner>> banners() async {
    final rows = await _db.from('banners').select().order('sort_order').order('created_at');
    final paths = rows.map((r) => r['image_path'] as String).toList();
    final urls = <String, String>{};
    if (paths.isNotEmpty) {
      for (final s in await _db.storage.from(AppConfig.mediaBucket).createSignedUrls(paths, 3600)) {
        urls[s.path] = s.signedUrl;
      }
    }
    return rows
        .map((r) => AdminBanner(
              id: r['id'] as String,
              title: r['title'] as String? ?? '',
              subtitle: r['subtitle'] as String? ?? '',
              imagePath: r['image_path'] as String,
              imageUrl: urls[r['image_path']],
              category: r['category'] as String?,
              active: r['active'] == true,
            ))
        .toList();
  }

  /// Uploads a banner photo into the product-images bucket and returns its path.
  Future<String> uploadBannerImage(Uint8List bytes, String extension) async {
    final path = 'banners/${DateTime.now().millisecondsSinceEpoch}.$extension';
    final type = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'avif' => 'image/avif',
      _ => 'image/jpeg',
    };
    await _db.storage.from(AppConfig.mediaBucket).uploadBinary(path, bytes, fileOptions: FileOptions(contentType: type));
    return path;
  }

  Future<void> addBanner({required String title, required String subtitle, required String imagePath, String? category}) async {
    await _db.from('banners').insert({
      'title': title,
      'subtitle': subtitle,
      'image_path': imagePath,
      'category': category,
      'active': true,
    });
  }

  Future<void> setBannerActive(String id, bool active) async {
    await _db.from('banners').update({'active': active}).eq('id', id);
  }

  Future<void> deleteBanner(String id) async {
    await _db.from('banners').delete().eq('id', id);
  }

  // ---- Reviews ---------------------------------------------------------------------------------

  Future<List<AdminReview>> pendingReviews() async {
    final rows = await _db.from('reviews').select().eq('approved', false).order('created_at', ascending: false);
    return rows
        .map((r) => AdminReview(
              id: r['id'] as String,
              productId: r['product_id'] as String,
              author: r['author_name'] as String? ?? 'Customer',
              rating: (r['rating'] as num?)?.toInt() ?? 5,
              comment: r['comment'] as String? ?? '',
              createdAt: DateTime.tryParse('${r['created_at']}')?.toLocal() ?? DateTime.now(),
            ))
        .toList();
  }

  Future<void> approveReview(String id) async {
    await _db.from('reviews').update({'approved': true}).eq('id', id);
  }

  Future<void> deleteReview(String id) async {
    await _db.from('reviews').delete().eq('id', id);
  }

  // ---- Referral rewards ------------------------------------------------------------------------

  Future<List<AdminReward>> rewards() async {
    final rows = await _db.from('referral_rewards').select().order('created_at', ascending: false);
    return rows
        .map((r) => AdminReward(
              id: r['id'] as String,
              referrerId: r['referrer_id'] as String,
              reward: r['reward'] as String? ?? '',
              status: r['status'] as String? ?? 'pending',
              createdAt: DateTime.tryParse('${r['created_at']}')?.toLocal() ?? DateTime.now(),
            ))
        .toList();
  }

  /// Every customer's referral code, keyed by user id, so rewards can show whose code earned them.
  Future<Map<String, String>> referralCodes() async {
    final rows = await _db.from('profiles').select('user_id,referral_code');
    return {for (final r in rows) r['user_id'] as String: r['referral_code'] as String};
  }

  Future<String?> userIdForReferralCode(String code) async {
    final row = await _db.from('profiles').select('user_id').eq('referral_code', code.trim().toUpperCase()).maybeSingle();
    return row?['user_id'] as String?;
  }

  /// Rewards the owner adds by hand, so they start as approved.
  Future<void> addReward({required String referrerId, required String reward}) async {
    await _db.from('referral_rewards').insert({'referrer_id': referrerId, 'reward': reward, 'status': 'approved'});
  }

  Future<void> setRewardStatus(String id, String status) async {
    await _db.from('referral_rewards').update({'status': status}).eq('id', id);
  }

  // ---- Stock -----------------------------------------------------------------------------------

  Future<List<AdminProductStock>> productStock() async {
    final rows = await _db.from('products').select('id,name,stock_status').order('name');
    return rows
        .map((r) => AdminProductStock(
              id: r['id'] as String,
              name: r['name'] as String? ?? '',
              status: r['stock_status'] as String? ?? 'in_stock',
            ))
        .toList();
  }

  Future<void> setStockStatus(String id, String status) async {
    await _db.from('products').update({'stock_status': status}).eq('id', id);
  }
}