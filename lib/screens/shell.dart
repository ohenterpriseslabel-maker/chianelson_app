import 'package:flutter/material.dart';

import '../app_state.dart';
import 'account_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'shop_screen.dart';
import 'wishlist_screen.dart';

/// The bottom navigation: Home, Shop, Wishlist, Orders, Account.
class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: state.selectedTab,
      builder: (context, index, _) => Scaffold(
        body: IndexedStack(
          index: index,
          children: [
            HomeScreen(),
            ShopScreen(),
            WishlistScreen(),
            OrdersScreen(),
            AccountScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => state.selectedTab.value = i,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Shop'),
            NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Wishlist'),
            NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'Orders'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
          ],
        ),
      ),
    );
  }
}