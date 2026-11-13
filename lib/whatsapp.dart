import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'models.dart';

Future<void> _openWhatsApp(BuildContext context, String text) async {
  final uri = Uri.parse('https://wa.me/${AppConfig.whatsappNumber}?text=${Uri.encodeComponent(text)}');
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('WhatsApp could not be opened on this phone.')),
    );
  }
}

/// Asks about one product. The message carries the product's page, so WhatsApp shows its photo.
Future<void> enquireOnWhatsApp(BuildContext context, Product product, {String? colour}) {
  final colourText = colour == null ? '' : ' in $colour';
  return _openWhatsApp(
    context,
    "Hello CHIANELSON, I'm interested in the ${product.name}$colourText.\n${product.pageUrl}\nPlease share the price and availability.",
  );
}

/// Sends the cart summary to WhatsApp to place the order.
Future<void> checkoutOnWhatsApp(BuildContext context, String summary) => _openWhatsApp(context, summary);

Future<void> chatOnWhatsApp(BuildContext context) =>
    _openWhatsApp(context, "Hello CHIANELSON, I'd like to ask about your home gadgets.");