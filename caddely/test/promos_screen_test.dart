import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/models/grocery_item.dart';
import 'package:caddely/models/purchase_record.dart';
import 'package:caddely/providers/grocery_provider.dart';
import 'package:caddely/providers/history_provider.dart';
import 'package:caddely/providers/shell_navigation_provider.dart';
import 'package:caddely/providers/store_preferences_provider.dart';
import 'package:caddely/screens/promos_screen.dart';
import 'package:caddely/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/fake_storage_service.dart';

Future<ShellNavigationProvider> pumpPromosScreen(
  WidgetTester tester, {
  required FakeStorageService storage,
}) async {
  final groceryProvider = GroceryProvider(storage);
  final historyProvider = HistoryProvider(storage);
  final storePreferencesProvider = StorePreferencesProvider(storage);
  final navigationProvider = ShellNavigationProvider()..goToPromos();

  await Future.wait([
    groceryProvider.load(),
    historyProvider.load(),
    storePreferencesProvider.load(),
  ]);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: groceryProvider),
        ChangeNotifierProvider.value(value: historyProvider),
        ChangeNotifierProvider.value(value: storePreferencesProvider),
        ChangeNotifierProvider.value(value: navigationProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const PromosScreen(),
      ),
    ),
  );

  return navigationProvider;
}

void main() {
  testWidgets('shows empty state when no promo is useful', (tester) async {
    final storage = FakeStorageService();

    await pumpPromosScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    expect(find.text('Aucune promo utile pour l’instant'), findsOneWidget);
    expect(
      find.textContaining('Continue à utiliser ta liste'),
      findsOneWidget,
    );
  });

  testWidgets('promo already in list shows "Voir dans ma liste"', (tester) async {
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

    await pumpPromosScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    expect(find.text('Voir dans ma liste'), findsOneWidget);
    expect(find.text('Ajouter à ma liste'), findsNothing);
  });

  testWidgets('"Voir dans ma liste" navigates to list and sets highlighted product', (tester) async {
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

    final navigation = await pumpPromosScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    expect(find.text('Voir dans ma liste'), findsOneWidget);

    await tester.tap(find.text('Voir dans ma liste').first);
    await tester.pumpAndSettle();

    expect(navigation.currentIndex, 0);
    expect(navigation.highlightedProductName, isNotNull);
  });

  testWidgets('clearHighlight resets highlightedProductName to null', (tester) async {
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

    final navigation = await pumpPromosScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Voir dans ma liste').first);
    await tester.pumpAndSettle();

    expect(navigation.highlightedProductName, isNotNull);
    navigation.clearHighlight();
    expect(navigation.highlightedProductName, isNull);
  });

  testWidgets('adds a product from promo and goes back to list tab', (tester) async {
    final storage = FakeStorageService()
      ..history = [
        PurchaseRecord(
          productName: 'Café',
          purchaseCount: 4,
          lastPurchasedAt: DateTime(2026, 5, 24),
          quantityStats: const {'2': 4},
          categoryStats: const {'drinks': 4},
        ),
      ];

    final navigation = await pumpPromosScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    expect(find.text('Ajouter à ma liste'), findsOneWidget);

    await tester.tap(find.text('Ajouter à ma liste').first);
    await tester.pumpAndSettle();

    expect(storage.groceryItems, hasLength(1));
    expect(storage.groceryItems.single.name, 'Café moulu');
    expect(storage.groceryItems.single.quantity, 2);
    expect(storage.groceryItems.single.category, GroceryCategory.drinks);
    expect(navigation.currentIndex, 0);
  });
}
