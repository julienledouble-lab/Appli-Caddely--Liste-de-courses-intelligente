import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/models/grocery_item.dart';
import 'package:caddely/providers/app_preferences_provider.dart';
import 'package:caddely/providers/grocery_provider.dart';
import 'package:caddely/providers/history_provider.dart';
import 'package:caddely/providers/recipes_provider.dart';
import 'package:caddely/providers/store_preferences_provider.dart';
import 'package:caddely/screens/app_root.dart';
import 'package:caddely/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'support/fake_storage_service.dart';

Future<void> pumpTestApp(
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
      child: const MaterialApp(home: AppRoot()),
    ),
  );
}

Future<void> pumpStoresOnlyApp(
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
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OnboardingScreen(storesOnly: true),
                    ),
                  );
                },
                child: const Text('Ouvrir la config magasins'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'hasCompletedOnboarding false shows onboarding',
    (tester) async {
      final storage = FakeStorageService()..hasCompletedOnboarding = false;

      await pumpTestApp(tester, storage: storage);
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue sur Caddely'), findsOneWidget);
    },
  );

  testWidgets(
    'hasCompletedOnboarding true shows main app',
    (tester) async {
      final storage = FakeStorageService()..hasCompletedOnboarding = true;

      await pumpTestApp(tester, storage: storage);
      await tester.pumpAndSettle();

      expect(find.text('Liste'), findsOneWidget);
    },
  );

  testWidgets(
    'finishing onboarding saves stores and marks onboarding completed',
    (tester) async {
      final storage = FakeStorageService()..hasCompletedOnboarding = false;

      await pumpTestApp(tester, storage: storage);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Commencer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Carrefour'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Leclerc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Voir ma liste'));
      await tester.pumpAndSettle();

      expect(storage.hasCompletedOnboarding, isTrue);
      expect(storage.stores.where((store) => store.isPrimary).single.id, 'carrefour');
      expect(
        storage.stores
            .where((store) => store.isSelectedForComparison)
            .single
            .id,
        'leclerc',
      );
      expect(storage.groceryItems, isEmpty);
      expect(storage.history, isEmpty);
      expect(find.text('Liste'), findsOneWidget);
    },
  );

  testWidgets(
    'empty list quick suggestions add a product without creating habits',
    (tester) async {
      final storage = FakeStorageService()..hasCompletedOnboarding = true;

      await pumpTestApp(tester, storage: storage);
      await tester.pumpAndSettle();

      expect(find.text('Ajoute tes premiers produits'), findsOneWidget);
      expect(
        find.textContaining('Plus tu utilises Caddely'),
        findsOneWidget,
      );
      expect(find.text('Lait'), findsOneWidget);
      expect(find.text('Pain'), findsOneWidget);

      await tester.tap(find.text('Lait'));
      await tester.pumpAndSettle();

      expect(storage.groceryItems.any((item) => item.name == 'Lait'), isTrue);
      expect(storage.history, isEmpty);
    },
  );

  testWidgets(
    'storesOnly updates stores without welcome step or product suggestions',
    (tester) async {
      final storage = FakeStorageService()
        ..hasCompletedOnboarding = true
        ..groceryItems = [
          GroceryItem(
            id: 'item-1',
            name: 'Lait',
            quantity: 2,
            category: GroceryCategory.fresh,
            addedAt: DateTime(2026, 5, 24),
          ),
        ];

      await pumpStoresOnlyApp(tester, storage: storage);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ouvrir la config magasins'));
      await tester.pumpAndSettle();

      expect(find.text('Bienvenue sur Caddely'), findsNothing);
      expect(find.text('Commencer'), findsNothing);
      expect(find.text('Pain'), findsNothing);
      expect(find.text('Quel est ton magasin habituel ?'), findsOneWidget);

      await tester.tap(find.text('Carrefour'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(find.text('Quels autres magasins veux-tu comparer ?'), findsOneWidget);
      expect(find.text('Caf\u00E9'), findsNothing);

      await tester.tap(find.text('Leclerc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuer'));
      await tester.pumpAndSettle();

      expect(find.text('Configuration mise \u00E0 jour'), findsOneWidget);

      await tester.tap(find.text('Voir ma liste'));
      await tester.pumpAndSettle();

      expect(find.text('Ouvrir la config magasins'), findsOneWidget);
      expect(storage.stores.where((store) => store.isPrimary).single.id, 'carrefour');
      expect(
        storage.stores
            .where((store) => store.isSelectedForComparison)
            .map((store) => store.id)
            .toSet(),
        {'leclerc'},
      );
      expect(storage.groceryItems, hasLength(1));
      expect(storage.groceryItems.single.name, 'Lait');
      expect(storage.history, isEmpty);
    },
  );
}
