import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'models.dart';

/// Opens WhatsApp with a ready-written message about the product. A WhatsApp link can only carry text, so the message
/// includes the product's web page: WhatsApp shows that page's photo as a preview.
Future<void> enquireOnWhatsApp(BuildContext context, Product product) async {
  final text = "Hello CHIANELSON, I'm interested in the ${product.name}.\n${product.pageUrl}\nPlease share the price and availability.";
  final uri = Uri.parse('https://wa.me/${AppConfig.whatsappNumber}?text=${Uri.encodeComponent(text)}');
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp could not be opened on this phone.')));
  }
}

Future<void> chatOnWhatsApp(BuildContext context) async {
  final uri = Uri.parse('https://wa.me/${AppConfig.whatsappNumber}?text=${Uri.encodeComponent("Hello CHIANELSON, I'd like to ask about your home gadgets.")}');
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp could not be opened on this phone.')));
  }
}