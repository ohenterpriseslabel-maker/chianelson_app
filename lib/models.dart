import 'config.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "12 Nov 2026"
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// "₦25,000"
String ngn(double value) {
  final digits = value.round().toString();
  final grouped = digits.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  return '₦$grouped';
}

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
    this.price,
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
  final List<String> images;
  final DateTime createdAt;

  /// Price in naira. null means "price on request".
  final double? price;

  /// The website's photo, used when a product has no photo uploaded yet.
  String get fallbackImageUrl => '${AppConfig.siteUrl}/img/products/$id.jpg';
  String get coverUrl => images.isNotEmpty ? images.first : fallbackImageUrl;
  List<String> get gallery => images.isNotEmpty ? images : [fallbackImageUrl];
  String get pageUrl => '${AppConfig.siteUrl}/products/$id';
  bool get inStock => stock != StockStatus.outOfStock;

  factory Product.fromRow(Map<String, dynamic> row, {List<String> images = const []}) {
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
      price: (row['price_ngn'] as num?)?.toDouble(),
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

/// An order found by reference and phone number.
class TrackedOrder {
  const TrackedOrder({
    required this.reference,
    required this.summary,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String reference;
  final String summary;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TrackedOrder.fromJson(Map<String, dynamic> j) => TrackedOrder(
        reference: '${j['reference']}',
        summary: '${j['summary']}',
        status: '${j['status']}',
        createdAt: _date(j['created_at']),
        updatedAt: _date(j['updated_at']),
      );
}