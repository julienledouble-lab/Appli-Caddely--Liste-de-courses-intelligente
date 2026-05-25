import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/models/grocery_item.dart';
import 'package:caddely/models/purchase_record.dart';
import 'package:caddely/models/store.dart';
import 'package:caddely/providers/app_preferences_provider.dart';
import 'package:caddely/providers/grocery_provider.dart';
import 'package:caddely/providers/history_provider.dart';
import 'package:caddely/providers/shell_navigation_provider.dart';
import 'package:caddely/providers/store_preferences_provider.dart';
import 'package:caddely/screens/home_screen.dart';
import 'package:caddely/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/fake_storage_service.dart';

Future<void> pumpHomeScreen(
  WidgetTester tester, {
  required FakeStorageService storage,
}) async {
  final groceryProvider = GroceryProvider(storage);
  final historyProvider = HistoryProvider(storage);
  final appPreferencesProvider = AppPreferencesProvider(storage);
  final storePreferencesProvider = StorePreferencesProvider(storage);

  await Future.wait([
    groceryProvider.load(),
    historyProvider.load(),
    appPreferencesProvider.load(),
    storePreferencesProvider.load(),
  ]);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: groceryProvider),
        ChangeNotifierProvider.value(value: historyProvider),
        ChangeNotifierProvider.value(value: appPreferencesProvider),
        ChangeNotifierProvider.value(value: storePreferencesProvider),
        ChangeNotifierProvider(create: (_) => ShellNavigationProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    ),
  );
}

GroceryItem buildItem({
  required String id,
  required String name,
  required GroceryCategory category,
  required DateTime addedAt,
  int quantity = 1,
  bool isPicked = false,
}) {
  return GroceryItem(
    id: id,
    name: name,
    category: category,
    quantity: quantity,
    isPicked: isPicked,
    addedAt: addedAt,
  );
}

void main() {
  testWidgets('shows progress and next item without crashing on non-empty list', (
    tester,
  ) async {
    final storage = FakeStorageService()
      ..groceryItems = [
        buildItem(
          id: '1',
          name: 'Pommes',
          category: GroceryCategory.fruitsAndVegetables,
          quantity: 6,
          addedAt: DateTime(2026, 5, 25, 9),
        ),
        buildItem(
          id: '2',
          name: 'Lait',
          category: GroceryCategory.fresh,
          quantity: 2,
          addedAt: DateTime(2026, 5, 25, 10),
        ),
        buildItem(
          id: '3',
          name: 'Caf\u00E9',
          category: GroceryCategory.drinks,
          isPicked: true,
          addedAt: DateTime(2026, 5, 25, 11),
        ),
      ];

    await pumpHomeScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    expect(find.text('1 sur 3 produits pris'), findsOneWidget);
    expect(find.text('Prochain \u00E0 prendre'), findsOneWidget);
    expect(find.text('Pommes x6'), findsOneWidget);
  });

  testWidgets('category can be collapsed and expanded', (tester) async {
    final storage = FakeStorageService()
      ..groceryItems = [
        buildItem(
          id: '1',
          name: 'Lait',
          category: GroceryCategory.fresh,
          addedAt: DateTime(2026, 5, 25, 9),
        ),
      ];

    await pumpHomeScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    expect(find.text('Lait'), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggle-category-fresh')));
    await tester.pumpAndSettle();

    expect(find.text('Lait'), findsNothing);

    await tester.tap(find.byKey(const Key('expand-all-categories')));
    await tester.pumpAndSettle();

    expect(find.text('Lait'), findsOneWidget);
  });

  testWidgets('hide and show picked items updates summary and persistence', (
    tester,
  ) async {
    final storage = FakeStorageService()
      ..groceryItems = [
        buildItem(
          id: 'picked-1',
          name: 'Caf\u00E9',
          category: GroceryCategory.drinks,
          isPicked: true,
          addedAt: DateTime(2026, 5, 25, 10),
        ),
      ];

    await pumpHomeScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    // R\u00E9sum\u00E9 "1 produit d\u00E9j\u00E0 pris" absent \u2192 les produits pris sont affich\u00E9s
    expect(find.text('1 produit d\u00E9j\u00E0 pris'), findsNothing);

    await tester.tap(find.byKey(const Key('toggle-picked-visibility')));
    await tester.pumpAndSettle();

    // R\u00E9sum\u00E9 pr\u00E9sent \u2192 les produits pris sont masqu\u00E9s
    expect(find.text('1 produit d\u00E9j\u00E0 pris'), findsOneWidget);
    expect(storage.hidePickedItems, isTrue);

    await tester.tap(find.byKey(const Key('toggle-picked-visibility')));
    await tester.pumpAndSettle();

    // R\u00E9sum\u00E9 absent \u00E0 nouveau \u2192 les produits pris sont de nouveau affich\u00E9s
    expect(find.text('1 produit d\u00E9j\u00E0 pris'), findsNothing);
    expect(storage.hidePickedItems, isFalse);
  });

  testWidgets('empty list still shows helper content safely', (tester) async {
    final storage = FakeStorageService();

    await pumpHomeScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    expect(find.text('Ta liste est vide'), findsOneWidget);
    expect(find.text('Ajoute tes premiers produits'), findsOneWidget);
  });

  testWidgets('shows promo shortcut when useful promos exist for current list', (
    tester,
  ) async {
    final storage = FakeStorageService()
      ..groceryItems = [
        buildItem(
          id: '1',
          name: 'Café',
          category: GroceryCategory.drinks,
          addedAt: DateTime(2026, 5, 25),
        ),
      ];

    await pumpHomeScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    expect(find.textContaining('promo utile'), findsOneWidget);
    expect(find.text('Voir les promos'), findsOneWidget);
  });

  testWidgets('does not show promo shortcut when no relevant promo exists', (
    tester,
  ) async {
    final storage = FakeStorageService()
      ..groceryItems = [
        buildItem(
          id: '1',
          name: 'Bananes',
          category: GroceryCategory.fruitsAndVegetables,
          addedAt: DateTime(2026, 5, 25),
        ),
      ];

    await pumpHomeScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    expect(find.text('Voir les promos'), findsNothing);
  });

  // ── Terminer mes courses ──────────────────────────────────────────────────

  testWidgets('"Terminer mes courses" chip appears when list is non-empty', (
    tester,
  ) async {
    final storage = FakeStorageService()
      ..groceryItems = [
        buildItem(
          id: '1',
          name: 'Lait',
          category: GroceryCategory.fresh,
          addedAt: DateTime(2026, 5, 25),
        ),
      ];

    await pumpHomeScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('finish-trip')), findsOneWidget);
  });

  testWidgets('"Terminer mes courses" ouvre la boîte de confirmation', (
    tester,
  ) async {
    final storage = FakeStorageService()
      ..groceryItems = [
        buildItem(
          id: '1',
          name: 'Lait',
          category: GroceryCategory.fresh,
          addedAt: DateTime(2026, 5, 25),
        ),
      ];

    await pumpHomeScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('finish-trip')));
    await tester.pumpAndSettle();

    expect(find.text('Terminer cette liste ?'), findsOneWidget);
    expect(
      find.textContaining('Ta liste actuelle sera vidée'),
      findsOneWidget,
    );
    expect(find.text('Annuler'), findsOneWidget);
    expect(find.text('Terminer'), findsOneWidget);
  });

  testWidgets('Annuler ne vide pas la liste', (tester) async {
    final storage = FakeStorageService()
      ..groceryItems = [
        buildItem(
          id: '1',
          name: 'Lait',
          category: GroceryCategory.fresh,
          addedAt: DateTime(2026, 5, 25),
        ),
      ];

    await pumpHomeScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('finish-trip')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(storage.groceryItems, hasLength(1));
    expect(find.text('Lait'), findsOneWidget);
  });

  testWidgets('Terminer vide toute la liste active', (tester) async {
    final storage = FakeStorageService()
      ..groceryItems = [
        buildItem(
          id: '1',
          name: 'Lait',
          category: GroceryCategory.fresh,
          addedAt: DateTime(2026, 5, 25),
        ),
        buildItem(
          id: '2',
          name: 'Pain',
          category: GroceryCategory.grocery,
          addedAt: DateTime(2026, 5, 25),
        ),
      ];

    await pumpHomeScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('finish-trip')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Terminer'));
    await tester.pumpAndSettle();

    expect(storage.groceryItems, isEmpty);
  });

  testWidgets("L'historique est conservé après fin des courses", (
    tester,
  ) async {
    final storage = FakeStorageService()
      ..groceryItems = [
        buildItem(
          id: '1',
          name: 'Lait',
          category: GroceryCategory.fresh,
          addedAt: DateTime(2026, 5, 25),
        ),
      ]
      ..history = [
        PurchaseRecord(
          productName: 'Café',
          purchaseCount: 5,
          lastPurchasedAt: DateTime(2026, 5, 20),
          quantityStats: const {'1': 5},
          categoryStats: const {'drinks': 5},
        ),
      ];

    await pumpHomeScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('finish-trip')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Terminer'));
    await tester.pumpAndSettle();

    expect(storage.history, hasLength(1));
    expect(storage.history.single.productName, 'Café');
  });

  testWidgets(
    "Les produits non pris ne sont pas ajoutés à l'historique",
    (tester) async {
      final storage = FakeStorageService()
        ..groceryItems = [
          buildItem(
            id: '1',
            name: 'Lait',
            category: GroceryCategory.fresh,
            addedAt: DateTime(2026, 5, 25),
          ),
          buildItem(
            id: '2',
            name: 'Beurre',
            category: GroceryCategory.fresh,
            addedAt: DateTime(2026, 5, 25),
          ),
        ];

      await pumpHomeScreen(tester, storage: storage);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('finish-trip')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terminer'));
      await tester.pumpAndSettle();

      expect(storage.groceryItems, isEmpty);
      expect(storage.history, isEmpty);
    },
  );

  testWidgets("Les magasins favoris sont conservés après fin des courses", (
    tester,
  ) async {
    final storage = FakeStorageService()
      ..groceryItems = [
        buildItem(
          id: '1',
          name: 'Lait',
          category: GroceryCategory.fresh,
          addedAt: DateTime(2026, 5, 25),
        ),
      ]
      ..stores = [
        const Store(id: 'leclerc', name: 'Leclerc', isPrimary: true),
      ];

    await pumpHomeScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('finish-trip')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Terminer'));
    await tester.pumpAndSettle();

    expect(storage.stores, isNotEmpty);
    expect(storage.stores.any((s) => s.id == 'leclerc'), isTrue);
  });

  testWidgets("L'état vide s'affiche proprement après fin des courses", (
    tester,
  ) async {
    final storage = FakeStorageService()
      ..groceryItems = [
        buildItem(
          id: '1',
          name: 'Lait',
          category: GroceryCategory.fresh,
          addedAt: DateTime(2026, 5, 25),
        ),
      ];

    await pumpHomeScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('finish-trip')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Terminer'));
    await tester.pumpAndSettle();

    expect(find.text('Ta liste est vide'), findsOneWidget);
    expect(find.text('Ajoute tes premiers produits'), findsOneWidget);
    expect(find.byKey(const Key('finish-trip')), findsNothing);
  });

  // ── Autocomplétion / suggestions ─────────────────────────────────────────

  testWidgets('tap sur une suggestion ajoute le produit avec qté historique', (
    tester,
  ) async {
    final storage = FakeStorageService()
      ..groceryItems = [
        buildItem(
          id: 'existing',
          name: 'Bananes',
          category: GroceryCategory.fruitsAndVegetables,
          addedAt: DateTime(2026, 5, 25),
        ),
      ]
      ..history = [
        PurchaseRecord(
          productName: 'Lait',
          purchaseCount: 3,
          lastPurchasedAt: DateTime(2026, 5, 20),
          quantityStats: const {'2': 3},
          categoryStats: const {'fresh': 3},
        ),
      ];

    await pumpHomeScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'la');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('suggestion-Lait')), findsOneWidget);

    await tester.tap(find.byKey(const Key('suggestion-Lait')));
    await tester.pumpAndSettle();

    expect(storage.groceryItems.any((i) => i.name == 'Lait'), isTrue);
    expect(
      storage.groceryItems.firstWhere((i) => i.name == 'Lait').quantity,
      2,
    );
  });

  testWidgets('produit déjà dans la liste absent des suggestions', (
    tester,
  ) async {
    final storage = FakeStorageService()
      ..groceryItems = [
        buildItem(
          id: '1',
          name: 'Lait',
          category: GroceryCategory.fresh,
          addedAt: DateTime(2026, 5, 25),
        ),
      ]
      ..history = [
        PurchaseRecord(
          productName: 'Lait',
          purchaseCount: 5,
          lastPurchasedAt: DateTime(2026, 5, 20),
          quantityStats: const {'1': 5},
          categoryStats: const {'fresh': 5},
        ),
      ];

    await pumpHomeScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'la');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('suggestion-Lait')), findsNothing);
    expect(storage.groceryItems.where((i) => i.name == 'Lait'), hasLength(1));
  });

  testWidgets(
    'catalogue local suggère "Café" quand historique vide et liste non vide',
    (tester) async {
      final storage = FakeStorageService()
        ..groceryItems = [
          buildItem(
            id: '1',
            name: 'Pain',
            category: GroceryCategory.grocery,
            addedAt: DateTime(2026, 5, 25),
          ),
        ];

      await pumpHomeScreen(tester, storage: storage);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'caf');
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('suggestion-Café')), findsOneWidget);
    },
  );

  testWidgets('"pate" suggère "Pâtes" grâce à la normalisation des accents', (
    tester,
  ) async {
    final storage = FakeStorageService()
      ..groceryItems = [
        buildItem(
          id: '1',
          name: 'Pain',
          category: GroceryCategory.grocery,
          addedAt: DateTime(2026, 5, 25),
        ),
      ];

    await pumpHomeScreen(tester, storage: storage);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'pate');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('suggestion-Pâtes')), findsOneWidget);
  });
}
