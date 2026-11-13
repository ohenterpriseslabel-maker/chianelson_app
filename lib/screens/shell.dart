import 'package:flutter/material.dart';

import '../app_state.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'more_screen.dart';
import 'shop_screen.dart';

/// The bottom navigation: Home, Shop, Cart, More.
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
          children: const [HomeScreen(), ShopScreen(), CartScreen(), MoreScreen()],
        ),
        bottomNavigationBar: AnimatedBuilder(
          animation: state.cart,
          builder: (context, _) {
            final count = state.cart.count;
            return NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => state.selectedTab.value = i,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront),
                  label: 'Shop',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    child: const Icon(Icons.shopping_bag),
                  ),
                  label: 'Cart',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.menu),
                  selectedIcon: Icon(Icons.menu_open),
                  label: 'More',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}