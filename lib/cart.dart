import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// One product in the cart, with the colour and quantity chosen.
class CartLine {
  CartLine({required this.productId, required this.quantity, this.colour});

  final String productId;
  int quantity;
  final String? colour;

  Map<String, dynamic> toJson() => {'productId': productId, 'quantity': quantity, 'colour': colour};

  factory CartLine.fromJson(Map<String, dynamic> j) => CartLine(
        productId: j['productId'] as String,
        quantity: (j['quantity'] as num).toInt(),
        colour: j['colour'] as String?,
      );
}

/// The shopping cart. It's kept on the phone, so customers don't need an account.
class CartStore extends ChangeNotifier {
  static const _key = 'cart_v1';
  final List<CartLine> _lines = [];

  List<CartLine> get lines => List.unmodifiable(_lines);
  int get count => _lines.fold(0, (sum, l) => sum + l.quantity);
  bool get isEmpty => _lines.isEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final decoded = (jsonDecode(raw) as List)
          .map((e) => CartLine.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _lines
        ..clear()
        ..addAll(decoded);
      notifyListeners();
    } catch (_) {
      // A damaged saved cart is simply ignored.
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_lines.map((l) => l.toJson()).toList()));
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  /// Adds to the cart. The same product in the same colour adds to the existing line.
  void add(String productId, {String? colour, int quantity = 1}) {
    final i = _lines.indexWhere((l) => l.productId == productId && l.colour == colour);
    if (i == -1) {
      _lines.add(CartLine(productId: productId, quantity: quantity, colour: colour));
    } else {
      _lines[i].quantity += quantity;
    }
    _changed();
  }

  void setQuantity(CartLine line, int quantity) {
    if (quantity <= 0) {
      _lines.remove(line);
    } else {
      line.quantity = quantity;
    }
    _changed();
  }

  void remove(CartLine line) {
    _lines.remove(line);
    _changed();
  }

  void clear() {
    _lines.clear();
    _changed();
  }

  /// The total in naira, or null when any product has no price yet.
  double? total(List<Product> products) {
    var sum = 0.0;
    for (final line in _lines) {
      Product? product;
      for (final p in products) {
        if (p.id == line.productId) product = p;
      }
      if (product == null || product.price == null) return null;
      sum += product.price! * line.quantity;
    }
    return sum;
  }
}