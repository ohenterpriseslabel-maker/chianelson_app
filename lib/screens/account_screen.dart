import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
import '../config.dart';
import '../models.dart';
import '../whatsapp.dart';
import 'admin_screen.dart';

/// Phone sign-in, the customer's referral code and rewards, and a shortcut to WhatsApp.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _friendCode = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _message;
  Future<ReferralSummary>? _summary;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _friendCode.dispose();
    super.dispose();
  }

  /// Turns 0802 333 4499 or 234802... into +2348023334499.
  String _normalise(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('234')) return '+$digits';
    if (digits.startsWith('0')) return '+234${digits.substring(1)}';
    return '+234$digits';
  }

  Future<void> _sendCode() async {
    final phone = _normalise(_phone.text);
    if (phone.length < 12) {
      setState(() => _message = 'Enter a valid phone number.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await AppScope.of(context).repo.sendCode(phone);
      setState(() => _codeSent = true);
    } catch (_) {
      setState(() => _message = 'We could not send the code. Check the number and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final state = AppScope.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await state.repo.verifyCode(_normalise(_phone.text), _code.text.trim());
      final friend = _friendCode.text.trim();
      if (friend.isNotEmpty) {
        final applied = await state.repo.applyReferral(friend);
        if (!applied && mounted) _message = 'You are signed in, but that referral code was not accepted.';
      }
      _summary = null;
      await state.refreshUserData();
    } catch (_) {
      setState(() => _message = 'That code did not work. Check it and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    final state = AppScope.of(context);
    await state.repo.signOut();
    setState(() {
      _codeSent = false;
      _code.clear();
      _summary = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Account', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (!state.signedIn) _signIn() else _profile(state),
          const SizedBox(height: 24),
          OutlinedButton.icon(onPressed: () => chatOnWhatsApp(context), icon: const Icon(Icons.chat), label: const Text('Chat with CHIANELSON on WhatsApp')),
        ],
      ),
    );
  }

  Widget _signIn() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sign in with your phone', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('Use the number you chat with us on, so your orders show up here.', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 14),
            TextField(controller: _phone, enabled: !_codeSent, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number', hintText: '0802 333 4499', border: OutlineInputBorder())),
            if (!_codeSent) ...[
              const SizedBox(height: 12),
              TextField(controller: _friendCode, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: "Friend's referral code (optional)", border: OutlineInputBorder())),
            ] else ...[
              const SizedBox(height: 12),
              TextField(controller: _code, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Code we sent you', border: OutlineInputBorder())),
            ],
            if (_message != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_message!, style: const TextStyle(color: Color(0xFFB3261E)))),
            const SizedBox(height: 14),
            FilledButton(onPressed: _busy ? null : (_codeSent ? _verify : _sendCode), child: Text(_busy ? 'Please wait…' : (_codeSent ? 'Verify and sign in' : 'Send me a code'))),
            if (_codeSent) TextButton(onPressed: _busy ? null : () => setState(() => _codeSent = false), child: const Text('Use a different number')),
          ],
        ),
      ),
    );
  }

  Widget _profile(AppState state) {
    _summary ??= state.repo.referral();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(leading: const Icon(Icons.phone_iphone), title: Text(state.repo.userPhone == null ? 'Signed in' : '+${state.repo.userPhone}'), subtitle: const Text('Signed in')),
        ),
        const AdminEntry(),
        const SizedBox(height: 16),
        FutureBuilder<ReferralSummary>(
          future: _summary,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
            final data = snap.data;
            if (data == null) return const Text('Your referral details could not be loaded right now.');
            return Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Refer a friend', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: AppConfig.cream, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppConfig.gold)),
                      child: Row(children: [
                        Expanded(child: Text(data.code, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 4))),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(minimumSize: const Size(110, 42)),
                          onPressed: () => Share.share('Shop CHIANELSON home gadgets: ${AppConfig.siteUrl}/?ref=${data.code}\nSign up in the CHIANELSON app with my code ${data.code}.'),
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Share'),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    Text('${data.friends} ${data.friends == 1 ? 'friend has' : 'friends have'} joined with your code.'),
                    if (data.terms.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(data.terms, style: const TextStyle(color: Colors.black54, fontSize: 13))),
                    if (data.rewards.isNotEmpty) ...[
                      const Divider(height: 28),
                      const Text('Your rewards', style: TextStyle(fontWeight: FontWeight.w700)),
                      for (final r in data.rewards)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.card_giftcard, color: AppConfig.gold),
                          title: Text(r.reward),
                          subtitle: Text('${r.status[0].toUpperCase()}${r.status.substring(1)} · ${formatDate(r.createdAt)}'),
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        TextButton(onPressed: _signOut, child: const Text('Sign out')),
      ],
    );
  }
}