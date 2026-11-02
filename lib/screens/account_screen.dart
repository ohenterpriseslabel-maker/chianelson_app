import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../config.dart';
import '../models.dart';
import '../whatsapp.dart';
import 'admin_screen.dart';
import 'change_password_card.dart';

/// Create an account or sign in with phone number and password, reset a forgotten password,
/// the customer's referral code and rewards, and a shortcut to WhatsApp.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

/// Turns 0802 333 4499 or 234802... into +2348023334499.
String _normalise(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
  if (digits.startsWith('+')) return digits;
  if (digits.startsWith('234')) return '+$digits';
  if (digits.startsWith('0')) return '+234${digits.substring(1)}';
  return '+234$digits';
}

/// Turns Supabase's technical messages into plain English.
String _friendly(String raw) {
  final text = raw.toLowerCase();
  if (text.contains('invalid login')) return 'That phone number and password do not match.';
  if (text.contains('already registered') || text.contains('already exists')) {
    return 'An account with this number already exists. Sign in instead.';
  }
  if (text.contains('password')) return 'Check your password and try again.';
  return 'We could not complete that. Please try again.';
}

class _AccountScreenState extends State<AccountScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _friendCode = TextEditingController();
  bool _creating = false;
  bool _busy = false;
  String? _message;
  Future<ReferralSummary>? _summary;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _friendCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final phone = _normalise(_phone.text);
    final password = _password.text;

    if (phone.length < 13) {
      setState(() => _message = 'Enter a valid phone number, for example 0802 333 4499.');
      return;
    }
    if (password.length < 8) {
      setState(() => _message = 'Your password must be at least 8 characters.');
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (_creating) {
        await state.repo.signUp(phone, password);
        if (Supabase.instance.client.auth.currentSession == null) {
          if (mounted) {
            setState(() => _message =
                'Your account was created, but could not be signed in. Please contact CHIANELSON on WhatsApp.');
          }
          return;
        }
        final friend = _friendCode.text.trim();
        if (friend.isNotEmpty) {
          final applied = await state.repo.applyReferral(friend);
          if (!applied) {
            messenger.showSnackBar(const SnackBar(
              content: Text('You are signed in, but that referral code was not accepted.'),
            ));
          }
        }
      } else {
        await state.repo.signIn(phone, password);
      }
      _password.clear();
      _summary = null;
      await state.refreshUserData();
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = _friendly(e.message));
    } catch (_) {
      if (mounted) setState(() => _message = 'Something went wrong. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    await showDialog<void>(context: context, builder: (_) => const _ForgotPasswordDialog());
  }

  Future<void> _signOut() async {
    final state = AppScope.of(context);
    await state.repo.signOut();
    setState(() {
      _password.clear();
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
          OutlinedButton.icon(
            onPressed: () => chatOnWhatsApp(context),
            icon: const Icon(Icons.chat),
            label: const Text('Chat with CHIANELSON on WhatsApp'),
          ),
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
            Text(
              _creating ? 'Create your account' : 'Sign in',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              _creating
                  ? 'Use the number you chat with us on, so your orders show up here.'
                  : 'Enter the phone number and password you signed up with.',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '0802 333 4499',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: _creating ? 'Choose a password (at least 8 characters)' : 'Password',
                border: const OutlineInputBorder(),
              ),
            ),
            if (_creating) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _friendCode,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: "Friend's referral code (optional)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_message!, style: const TextStyle(color: Color(0xFFB3261E))),
              ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Please wait…' : (_creating ? 'Create account' : 'Sign in')),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _creating = !_creating;
                        _message = null;
                      }),
              child: Text(_creating ? 'I already have an account' : 'New here? Create an account'),
            ),
            if (!_creating)
              TextButton(
                onPressed: _busy ? null : _forgotPassword,
                child: const Text('Forgot password?'),
              ),
            if (!_creating)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => showDialog<void>(context: context, builder: (_) => const _StaffSignInDialog()),
                child: const Text('Staff sign in'),
              ),
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
          child: ListTile(
            leading: const Icon(Icons.phone_iphone),
            title: Text(state.repo.userPhone == null ? 'Signed in' : '+${state.repo.userPhone}'),
            subtitle: const Text('Signed in'),
          ),
        ),
        const SizedBox(height: 16),
        const AdminEntry(),
        const SizedBox(height: 16),
        FutureBuilder<ReferralSummary>(
          future: _summary,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
            }
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
                      decoration: BoxDecoration(
                        color: AppConfig.cream,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppConfig.gold),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Text(
                            data.code,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 4),
                          ),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(minimumSize: const Size(110, 42)),
                          onPressed: () => Share.share(
                            'Shop CHIANELSON home gadgets: ${AppConfig.siteUrl}/?ref=${data.code}\nSign up in the CHIANELSON app with my code ${data.code}.',
                          ),
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Share'),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    Text('${data.friends} ${data.friends == 1 ? 'friend has' : 'friends have'} joined with your code.'),
                    if (data.terms.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(data.terms, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                      ),
                    if (data.rewards.isNotEmpty) ...[
                      const Divider(height: 28),
                      const Text('Your rewards', style: TextStyle(fontWeight: FontWeight.w700)),
                      for (final r in data.rewards)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.card_giftcard, color: AppConfig.gold),
                          title: Text(r.reward),
                          subtitle: Text(
                            '${r.status[0].toUpperCase()}${r.status.substring(1)} · ${formatDate(r.createdAt)}',
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const ChangePasswordCard(),
        const SizedBox(height: 16),
        TextButton(onPressed: _signOut, child: const Text('Sign out')),
      ],
    );
  }
}

/// Reset a forgotten password with the phone number and the last 5 digits of it.
class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog();

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _phone = TextEditingController();
  final _reference = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _phone.dispose();
    _reference.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    final digits = _normalise(_phone.text).replaceAll(RegExp(r'\D'), '');
    final last5 = _reference.text.replaceAll(RegExp(r'\D'), '');
    final password = _password.text;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final state = AppScope.of(context);

    if (last5.length != 5) {
      setState(() => _message = 'Enter the last 5 digits of your phone number.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await Supabase.instance.client.rpc('reset_password_with_order', params: {
        '_phone': digits,
        '_last5': last5,
        '_new_password': password,
      });
      final text = result as String? ?? 'We could not reset your password. Please try again.';
      if (text != 'ok') {
        if (mounted) setState(() => _message = text);
        return;
      }
      await state.repo.signIn(digits, password);
      await state.refreshUserData();
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Your password has been reset. You are signed in.')));
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = _friendly(e.message));
    } catch (_) {
      if (mounted) setState(() => _message = 'Something went wrong. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the phone number you signed up with and its last 5 digits.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
            TextField(
              controller: _reference,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Last 5 digits of your phone number'),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password (at least 8 characters)'),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_message!, style: const TextStyle(color: Color(0xFFB3261E))),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _busy ? null : _reset, child: Text(_busy ? 'Please wait…' : 'Reset password')),
      ],
    );
  }
}

/// Staff sign-in with the email and password of the website admin account.
class _StaffSignInDialog extends StatefulWidget {
  const _StaffSignInDialog();

  @override
  State<_StaffSignInDialog> createState() => _StaffSignInDialogState();
}

class _StaffSignInDialogState extends State<_StaffSignInDialog> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final navigator = Navigator.of(context);
    final state = AppScope.of(context);
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _message = 'Enter the staff email address.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(email: email, password: _password.text);
      await state.refreshUserData();
      navigator.pop();
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = _friendly(e.message));
    } catch (_) {
      if (mounted) setState(() => _message = 'Something went wrong. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Staff sign in'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Staff email'),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_message!, style: const TextStyle(color: Color(0xFFB3261E))),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _busy ? null : _signIn, child: Text(_busy ? 'Please wait…' : 'Sign in')),
      ],
    );
  }
}