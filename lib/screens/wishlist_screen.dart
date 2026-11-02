import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (!state.signedIn) {
      return const SafeArea(child: NeedsSignIn(icon: Icons.favorite_border, message: 'Sign in to save the products you love and find them here.'));
    }
    final saved = state.wishlisted;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Your wishlist', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (saved.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('Tap the heart on any product to save it here.', textAlign: TextAlign.center)))
          else
            ProductGrid(saved),
        ],
      ),
    );
  }
}