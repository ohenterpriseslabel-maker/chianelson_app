import 'config.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
DateTime _date(dynamic raw) => DateTime.tryParse('${raw ?? ''}')?.toLocal() ?? DateTime.now();

class ProductFeature {
  const ProductFeature({required this.label, required this.value});
  final String label;
  final String value;
}

enum StockStatus {
  inStock('In stock'),
  lowStock('Low stock'),
  outOfStock('Out of stock');

  const StockStatus(this.label);
  final String label;

  static StockStatus parse(String? raw) => switch (raw) {
        'low_stock' => StockStatus.lowStock,
        'out_of_stock' => StockStatus.outOfStock,
        _ => StockStatus.inStock,
      };
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.rooms,
    required this.colours,
    required this.features,
    required this.featured,
    required this.stock,
    required this.images,
    required this.createdAt,
    this.video,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final List<String> rooms;
  final List<String> colours;
  final List<ProductFeature> features;
  final bool featured;
  final StockStatus stock;

  /// Uploaded photos (links that expire after a few hours, so they are fetched fresh on every load).
  final List<String> images;
  final String? video;
  final DateTime createdAt;

  /// Products that have no uploaded photo yet use the picture the website ships for them.
  String get fallbackImageUrl => '${AppConfig.siteUrl}/img/products/$id.jpg';
  String get coverUrl => images.isNotEmpty ? images.first : fallbackImageUrl;
  List<String> get gallery => images.isNotEmpty ? images : [fallbackImageUrl];

  /// The product's page on the website. Sharing it in WhatsApp shows the product photo as a preview.
  String get pageUrl => '${AppConfig.siteUrl}/products/$id';

  factory Product.fromRow(Map<String, dynamic> row, {List<String> images = const [], String? video}) {
    final features = (row['features'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => ProductFeature(label: '${m['label'] ?? ''}'.trim(), value: '${m['value'] ?? ''}'.trim()))
        .where((f) => f.label.isNotEmpty && f.value.isNotEmpty)
        .toList();
    return Product(
      id: row['id'] as String,
      name: row['name'] as String,
      category: row['category'] as String? ?? '',
      description: row['description'] as String? ?? '',
      rooms: List<String>.from(row['rooms'] as List? ?? const []),
      colours: List<String>.from(row['colours'] as List? ?? const []),
      features: features,
      featured: row['featured'] == true,
      stock: StockStatus.parse(row['stock_status'] as String?),
      images: images,
      createdAt: _date(row['created_at']),
      video: video,
    );
  }
}

class HomeBanner {
  const HomeBanner({required this.title, required this.subtitle, required this.imageUrl, this.category});
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? category;
}

class Review {
  const Review({required this.author, required this.rating, required this.comment, required this.createdAt});
  final String author;
  final int rating;
  final String comment;
  final DateTime createdAt;

  factory Review.fromRow(Map<String, dynamic> r) => Review(
        author: r['author_name'] as String? ?? 'Customer',
        rating: (r['rating'] as num?)?.toInt() ?? 5,
        comment: r['comment'] as String? ?? '',
        createdAt: _date(r['created_at']),
      );
}

/// The four stages a customer sees, in order.
const orderSteps = ['ordered', 'shipped', 'arrived_lagos', 'delivered'];

String orderStepLabel(String status) => switch (status) {
      'ordered' => 'Ordered',
      'shipped' => 'Shipped',
      'arrived_lagos' => 'Arrived Lagos',
      'delivered' => 'Delivered',
      _ => status,
    };

class Order {
  const Order({required this.id, required this.reference, required this.summary, required this.status, required this.createdAt, required this.updatedAt});
  final String id;
  final String reference;
  final String summary;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Order.fromRow(Map<String, dynamic> r) => Order(
        id: r['id'] as String,
        reference: r['reference'] as String? ?? '',
        summary: r['product_summary'] as String? ?? '',
        status: r['status'] as String? ?? 'ordered',
        createdAt: _date(r['created_at']),
        updatedAt: _date(r['updated_at']),
      );
}

class ReferralReward {
  const ReferralReward({required this.reward, required this.status, required this.createdAt});
  final String reward;
  final String status;
  final DateTime createdAt;
}

class ReferralSummary {
  const ReferralSummary({required this.code, required this.friends, required this.terms, required this.rewards});
  final String code;
  final int friends;
  final String terms;
  final List<ReferralReward> rewards;

  factory ReferralSummary.fromJson(Map<String, dynamic> json) => ReferralSummary(
        code: json['code'] as String? ?? '',
        friends: (json['friends'] as num?)?.toInt() ?? 0,
        terms: json['terms'] as String? ?? '',
        rewards: (json['rewards'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => ReferralReward(reward: '${m['reward']}', status: '${m['status']}', createdAt: _date(m['created_at'])))
            .toList(),
      );
}