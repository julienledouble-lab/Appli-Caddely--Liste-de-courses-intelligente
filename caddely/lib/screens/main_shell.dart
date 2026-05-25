import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shell_navigation_provider.dart';
import 'comparator_screen.dart';
import 'habits_screen.dart';
import 'home_screen.dart';
import 'promos_screen.dart';
import 'recipes_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShellNavigationProvider(),
      child: const _MainShellScaffold(),
    );
  }
}

class _MainShellScaffold extends StatelessWidget {
  const _MainShellScaffold();

  static const _screens = [
    HomeScreen(),
    PromosScreen(),
    ComparatorScreen(),
    HabitsScreen(),
    RecipesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<ShellNavigationProvider>();

    return Scaffold(
      body: IndexedStack(
        index: navigation.currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigation.currentIndex,
        onTap: navigation.setTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Liste',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            activeIcon: Icon(Icons.local_offer),
            label: 'Promos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows_outlined),
            activeIcon: Icon(Icons.compare_arrows),
            label: 'Comparateur',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Habitudes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Recettes',
          ),
        ],
      ),
    );
  }
}
