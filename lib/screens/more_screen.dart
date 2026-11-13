import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';
import '../whatsapp.dart';
import 'track_screen.dart';

/// Help, contact details, order tracking and social links.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const _tiktok = 'https://www.tiktok.com/@chianselsonhomegadgets';
  static const _instagram = 'https://www.instagram.com/chianselsonhomegadgets';
  static const _facebook = 'https://www.facebook.com/chianselsonhomegadgets';

  Future<void> _open(BuildContext context, String url) async {
    final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That link could not be opened.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const Text('More',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Brand.navy)),
          const SizedBox(height: 20),
          _Group(children: [
            _Tile(
              icon: Icons.local_shipping_outlined,
              title: 'Track an order',
              subtitle: 'Use your phone number and order reference',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const TrackScreen()),
              ),
            ),
            _Tile(
              icon: Icons.chat_bubble_outline,
              title: 'Chat on WhatsApp',
              subtitle: 'Ask about a product, price or delivery',
              onTap: () => chatOnWhatsApp(context),
            ),
          ]),
          const SizedBox(height: 16),
          _Group(children: [
            _Tile(
              icon: Icons.call_outlined,
              title: 'Call Tony',
              subtitle: '0802 333 4499',
              onTap: () => _open(context, 'tel:+2348023334499'),
            ),
            _Tile(
              icon: Icons.call_outlined,
              title: 'Call Chiamaka',
              subtitle: '0901 647 0793',
              onTap: () => _open(context, 'tel:+2349016470793'),
            ),
          ]),
          const SizedBox(height: 16),
          _Group(children: [
            _Tile(
              icon: Icons.music_note_outlined,
              title: 'TikTok',
              subtitle: '@chianselsonhomegadgets',
              onTap: () => _open(context, _tiktok),
            ),
            _Tile(
              icon: Icons.photo_camera_outlined,
              title: 'Instagram',
              subtitle: '@chianselsonhomegadgets',
              onTap: () => _open(context, _instagram),
            ),
            _Tile(
              icon: Icons.thumb_up_alt_outlined,
              title: 'Facebook',
              subtitle: 'CHIANELSON Home Gadgets',
              onTap: () => _open(context, _facebook),
            ),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Brand.line),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About CHIANELSON',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Brand.navy)),
                SizedBox(height: 8),
                Text(
                  'CHIANELSON Home Gadgets Limited brings practical, good-looking gadgets for the home. '
                  'Browse, add what you like to your cart, and send your order to us on WhatsApp. '
                  'We confirm the price, availability and payment with you directly.',
                  style: TextStyle(height: 1.5, color: Brand.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Brand.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 60, color: Brand.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Brand.gold.withValues(alpha: 0.15),
        child: Icon(icon, color: Brand.navy),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Brand.ink)),
      subtitle: Text(subtitle, style: const TextStyle(color: Brand.muted)),
      trailing: const Icon(Icons.chevron_right, color: Brand.muted),
      onTap: onTap,
    );
  }
}