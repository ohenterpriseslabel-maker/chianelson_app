import 'package:flutter/material.dart';

import '../admin_repository.dart';
import '../models.dart';

/// Records rewards for customers whose friends joined with their code, and tracks whether each one was used.
class AdminRewardsScreen extends StatefulWidget {
  const AdminRewardsScreen({super.key});

  @override
  State<AdminRewardsScreen> createState() => _AdminRewardsScreenState();
}

class _RewardData {
  const _RewardData(this.rewards, this.codes);
  final List<AdminReward> rewards;
  final Map<String, String> codes;
}

const _statuses = ['pending', 'approved', 'redeemed'];

class _AdminRewardsScreenState extends State<AdminRewardsScreen> {
  final _repo = AdminRepository();
  final _code = TextEditingController();
  final _reward = TextEditingController();
  bool _saving = false;
  String? _message;
  late Future<_RewardData> _data = _load();

  @override
  void dispose() {
    _code.dispose();
    _reward.dispose();
    super.dispose();
  }

  Future<_RewardData> _load() async => _RewardData(await _repo.rewards(), await _repo.referralCodes());

  void _reload() {
    setState(() => _data = _load());
  }

  Future<void> _award() async {
    final code = _code.text.trim();
    final reward = _reward.text.trim();
    if (code.isEmpty || reward.isEmpty) {
      setState(() => _message = 'Enter the referral code and the reward.');
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final referrerId = await _repo.userIdForReferralCode(code);
      if (referrerId == null) {
        setState(() => _message = 'No customer has that referral code.');
        return;
      }
      await _repo.addReward(referrerId: referrerId, reward: reward);
      _code.clear();
      _reward.clear();
      setState(() => _message = 'Reward added.');
      _reload();
    } catch (_) {
      setState(() => _message = 'The reward could not be saved. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setStatus(AdminReward reward, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.setRewardStatus(reward.id, status);
      if (mounted) _reload();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('The reward could not be updated.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Referral rewards')),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _data;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add a reward', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    const Text('Enter the code of the customer who referred a friend, and the reward you agreed.', style: TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 12),
                    TextField(controller: _code, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Referral code')),
                    TextField(controller: _reward, decoration: const InputDecoration(labelText: 'Reward, e.g. ₦2,000 off next order')),
                    if (_message != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_message!)),
                    const SizedBox(height: 8),
                    FilledButton(onPressed: _saving ? null : _award, child: Text(_saving ? 'Saving…' : 'Add reward')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('All rewards', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            FutureBuilder<_RewardData>(
              future: _data,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
                if (snap.hasError) return const Text('Rewards could not be loaded. Pull down to try again.');
                final data = snap.data!;
                if (data.rewards.isEmpty) return const Text('No rewards yet.', style: TextStyle(color: Colors.black54));
                return Column(
                  children: [
                    for (final r in data.rewards)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(r.reward),
                          subtitle: Text('Code ${data.codes[r.referrerId] ?? 'unknown'} · ${formatDate(r.createdAt)}'),
                          trailing: DropdownButton<String>(
                            value: _statuses.contains(r.status) ? r.status : 'pending',
                            underline: const SizedBox.shrink(),
                            items: [for (final s in _statuses) DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1)))],
                            onChanged: (s) {
                              if (s != null && s != r.status) _setStatus(r, s);
                            },
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}