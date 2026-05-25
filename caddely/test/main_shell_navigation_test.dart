import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/models/grocery_item.dart';
import 'package:caddely/providers/app_preferences_provider.dart';
import 'package:caddely/providers/grocery_provider.dart';
import 'package:caddely/providers/history_provider.dart';
import 'package:caddely/providers/recipes_provider.dart';
import 'package:caddely/providers/shell_navigation_provider.dart';
import 'package:caddely/providers/store_preferences_provider.dart';
import 'package:caddely/screens/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/fake_storage_service.dart';

Future<void> pumpMainShell(
  WidgetTester tester, {
  required FakeStorageService storage,
}) async {
  final groceryProvider = GroceryProvider(storage);
  final historyProvider = HistoryProvider(storage);
  final recipesProvider = RecipesProvider(storage);
  final storePreferencesProvider = StorePreferencesProvider(storage);
  final appPreferencesProvider = AppPreferencesProvider(storage);

  await Future.wait([
    groceryProvider.load(),
    historyProvider.load(),
    recipesProvider.load(),
    storePreferencesProvider.load(),
    appPreferencesProvider.load(),
  ]);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: groceryProvider),
        ChangeNotifierProvider.value(value: historyProvider),
        ChangeNotifierProvider.value(value: recipesProvider),
        ChangeNotifierProvider.value(value: storePreferencesProvider),
        ChangeNotifierProvider.value(value: appPreferencesProvider),
      ],
      child: const MaterialApp(home: MainShell()),
    ),
  );
}

void main() {
  testWidgets('"Voir dans ma liste" returns to list tab', (tester) async {
    final storage = FakeStorageService()
      ..groceryItems = [
        GroceryItem(
          id: '1',
          name: 'Café',
          quantity: 2,
          category: GroceryCategory.drinks,
          addedAt: DateTime(2026, 5, 25),
        ),
      ];

    await pumpMainShell(tester, storage: storage);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Promos'));
    await tester.pumpAndSettle();

    expect(find.text('Voir dans ma liste'), findsOneWidget);

    await tester.tap(find.text('Voir dans ma liste').first);
    await tester.pump();

    final navBar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(navBar.currentIndex, 0);
  });

  test('goToListWithHighlight sets product name and navigates to list tab', () {
    final provider = ShellNavigationProvider()..goToPromos();
    expect(provider.currentIndex, 1);

    provider.goToListWithHighlight('Café moulu');
    expect(provider.currentIndex, 0);
    expect(provider.highlightedProductName, 'Café moulu');
  });

  test('clearHighlight removes highlighted product name without crash', () {
    final provider = ShellNavigationProvider();
    provider.goToListWithHighlight('Produit inexistant');
    expect(provider.highlightedProductName, isNotNull);
    provider.clearHighlight();
    expect(provider.highlightedProductName, isNull);

    // Calling clearHighlight again when already null must not crash
    provider.clearHighlight();
    expect(provider.highlightedProductName, isNull);
  });

  testWidgets('promo card can navigate to comparator tab', (tester) async {
    final storage = FakeStorageService()
      ..groceryItems = [
        GroceryItem(
          id: '1',
          name: 'Café',
          quantity: 2,
          category: GroceryCategory.drinks,
          addedAt: DateTime(2026, 5, 25),
        ),
      ];

    await pumpMainShell(tester, storage: storage);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Promos'));
    await tester.pumpAndSettle();

    expect(find.text('Comparer mon panier'), findsOneWidget);

    await tester.tap(find.text('Comparer mon panier').first);
    await tester.pumpAndSettle();

    expect(find.text('COMPARAISON PAR MAGASIN'), findsOneWidget);
  });

  testWidgets('recipes tab is reachable from main navigation', (tester) async {
    final storage = FakeStorageService();

    await pumpMainShell(tester, storage: storage);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recettes'));
    await tester.pumpAndSettle();

    expect(find.text('Aucune recette enregistrée'), findsOneWidget);
    final navBar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(navBar.currentIndex, 4);
  });
}
