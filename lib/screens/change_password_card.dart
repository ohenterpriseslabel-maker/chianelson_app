import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lets a signed-in customer choose a new password.
class ChangePasswordCard extends StatefulWidget {
  const ChangePasswordCard({super.key});

  @override
  State<ChangePasswordCard> createState() => _ChangePasswordCardState();
}

class _ChangePasswordCardState extends State<ChangePasswordCard> {
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _message;
  bool _ok = false;

  @override
  void dispose() {
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _change() async {
    final password = _new.text;
    if (password.length < 8) {
      setState(() {
        _ok = false;
        _message = 'Your new password must be at least 8 characters.';
      });
      return;
    }
    if (password != _confirm.text) {
      setState(() {
        _ok = false;
        _message = 'The two passwords do not match.';
      });
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: password));
      _new.clear();
      _confirm.clear();
      if (mounted) {
        setState(() {
          _ok = true;
          _message = 'Your password has been changed.';
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _ok = false;
          _message = e.message.toLowerCase().contains('same')
              ? 'Choose a password different from your current one.'
              : 'Your password could not be changed. Please try again.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ok = false;
          _message = 'Something went wrong. Check your connection and try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _new,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password (at least 8 characters)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Type the new password again', border: OutlineInputBorder()),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _message!,
                  style: TextStyle(color: _ok ? const Color(0xFF2E7D4F) : const Color(0xFFB3261E)),
                ),
              ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: _busy ? null : _change,
              child: Text(_busy ? 'Saving…' : 'Change password'),
            ),
          ],
        ),
      ),
    );
  }
}