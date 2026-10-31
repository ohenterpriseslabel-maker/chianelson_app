import 'package:flutter/material.dart';

/// Settings for the app. The three build-time values are passed with --dart-define so no keys live in the code:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
/// Use the same values as VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY in the website's .env file.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const siteUrl = String.fromEnvironment('SITE_URL', defaultValue: 'https://chianelson.com');

  /// WhatsApp number for enquiries: digits only, with the country code.
  static const whatsappNumber = '2348023334499';

  /// Storage bucket that holds product photos, videos and banners (the same one the website uses).
  static const mediaBucket = 'product-images';

  // Brand colours, matching the website.
  static const navy = Color(0xFF1E2B4F);
  static const cream = Color(0xFFFBF8F1);
  static const gold = Color(0xFFB8964A);
}