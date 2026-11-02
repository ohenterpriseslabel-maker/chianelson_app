import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../admin_repository.dart';
import '../widgets.dart';

/// Home page banners: add a photo and text, hide a banner without deleting it, or remove it.
class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  final _repo = AdminRepository();
  late Future<List<AdminBanner>> _banners = _repo.banners();

  void _reload() {
    setState(() => _banners = _repo.banners());
  }

  Future<void> _add() async {
    final saved = await showDialog<bool>(context: context, builder: (_) => const _BannerDialog());
    if (saved == true && mounted) _reload();
  }

  Future<void> _setActive(AdminBanner banner, bool active) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.setBannerActive(banner.id, active);
      if (mounted) _reload();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('The banner could not be updated.')));
    }
  }

  Future<void> _delete(AdminBanner banner) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this banner?'),
        content: Text(banner.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repo.deleteBanner(banner.id);
      if (mounted) _reload();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('The banner could not be deleted.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home banners')),
      floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Add banner')),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _banners;
        },
        child: FutureBuilder<List<AdminBanner>>(
          future: _banners,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return const Center(child: Text('Banners could not be loaded. Pull down to try again.'));
            final banners = snap.data ?? const <AdminBanner>[];
            if (banners.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No banners yet. The app shows a default banner until you add one.', textAlign: TextAlign.center)));
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                for (final b in banners)
                  _BannerCard(
                    banner: b,
                    onActive: (v) => _setActive(b, v),
                    onDelete: () => _delete(b),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner, required this.onActive, required this.onDelete});
  final AdminBanner banner;
  final ValueChanged<bool> onActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final link = banner.category == null || banner.category!.isEmpty ? 'Not linked to a room' : 'Opens the ${banner.category} collection';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 7,
            child: banner.imageUrl == null
                ? const ColoredBox(color: Color(0xFFF1ECDF), child: Center(child: Icon(Icons.image_outlined)))
                : ProductImage(url: banner.imageUrl!),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(banner.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (banner.subtitle.isNotEmpty) Text(banner.subtitle),
                      Text(link, style: const TextStyle(color: Colors.black45, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(tooltip: 'Delete banner', icon: const Icon(Icons.delete_outline), onPressed: onDelete),
              ],
            ),
          ),
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('Shown in the app'),
            value: banner.active,
            onChanged: onActive,
          ),
        ],
      ),
    );
  }
}

class _BannerDialog extends StatefulWidget {
  const _BannerDialog();

  @override
  State<_BannerDialog> createState() => _BannerDialogState();
}

class _BannerDialogState extends State<_BannerDialog> {
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _category = TextEditingController();
  XFile? _file;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (picked != null && mounted) setState(() => _file = picked);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final file = _file;
    if (title.isEmpty || file == null) {
      setState(() => _error = 'Add a title and a photo.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final name = file.name.toLowerCase();
      final dot = name.lastIndexOf('.');
      final raw = dot == -1 ? 'jpg' : name.substring(dot + 1);
      final ext = raw == 'jpeg' ? 'jpg' : (const {'png', 'webp', 'avif'}.contains(raw) ? raw : 'jpg');

      final bytes = await file.readAsBytes();
      final path = await _repo.uploadBannerImage(bytes, ext);
      final category = _category.text.trim();
      await _repo.addBanner(
        title: title,
        subtitle: _subtitle.text.trim(),
        imagePath: path,
        category: category.isEmpty ? null : category,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'The banner could not be saved. Try a smaller photo, then try again.';
        });
      }
    }
  }

  final _repo = AdminRepository();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New banner'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _saving ? null : _pick,
              icon: const Icon(Icons.photo_outlined),
              label: Text(_file == null ? 'Choose a photo' : _file!.name, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 8),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: _subtitle, decoration: const InputDecoration(labelText: 'Subtitle (optional)')),
            TextField(controller: _category, decoration: const InputDecoration(labelText: 'Room to open, e.g. Kitchen (optional)')),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Color(0xFFB3261E)))),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save banner')),
      ],
    );
  }
}