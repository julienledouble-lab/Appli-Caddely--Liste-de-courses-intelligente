import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/models/purchase_record.dart';
import 'package:caddely/utils/suggestion_engine.dart';
import 'package:flutter_test/flutter_test.dart';

PurchaseRecord _record(
  String name,
  int count,
  GroceryCategory cat, {
  int quantity = 1,
}) {
  return PurchaseRecord(
    productName: name,
    purchaseCount: count,
    lastPurchasedAt: DateTime(2026, 5, 1),
    quantityStats: {'$quantity': count},
    categoryStats: {cat.storageKey: count},
  );
}

void main() {
  group('buildSuggestions - catalogue local enrichi', () {
    test('"tom" propose "Tomates"', () {
      final result = buildSuggestions(
        sortedHistory: const [],
        query: 'tom',
        excludedNames: const {},
      );

      expect(result.any((s) => s.productName == 'Tomates'), isTrue);
    });

    test('"moz" propose "Mozzarella"', () {
      final result = buildSuggestions(
        sortedHistory: const [],
        query: 'moz',
        excludedNames: const {},
      );

      expect(result.any((s) => s.productName == 'Mozzarella'), isTrue);
    });

    test('"pate" propose "Pâtes" grâce à la normalisation des accents', () {
      final result = buildSuggestions(
        sortedHistory: const [],
        query: 'pate',
        excludedNames: const {},
      );

      expect(result.any((s) => s.productName == 'Pâtes'), isTrue);
    });

    test('"sham" propose "Shampooing"', () {
      final result = buildSuggestions(
        sortedHistory: const [],
        query: 'sham',
        excludedNames: const {},
      );

      expect(result.any((s) => s.productName == 'Shampooing'), isTrue);
    });

    test('"less" propose "Lessive"', () {
      final result = buildSuggestions(
        sortedHistory: const [],
        query: 'less',
        excludedNames: const {},
      );

      expect(result.any((s) => s.productName == 'Lessive'), isTrue);
    });

    test('"comp" propose "Compote"', () {
      final result = buildSuggestions(
        sortedHistory: const [],
        query: 'comp',
        excludedNames: const {},
      );

      expect(result.any((s) => s.productName == 'Compote'), isTrue);
    });

    test('les suggestions du catalogue ont frequency == 0', () {
      final result = buildSuggestions(
        sortedHistory: const [],
        query: 'lait',
        excludedNames: const {},
      );

      expect(result, isNotEmpty);
      expect(result.every((suggestion) => suggestion.frequency == 0), isTrue);
    });
  });

  group('buildSuggestions - historique prioritaire', () {
    test("l'historique passe avant le catalogue", () {
      final history = [
        _record('Lait bio', 3, GroceryCategory.fresh, quantity: 2),
      ];

      final result = buildSuggestions(
        sortedHistory: history,
        query: 'lait',
        excludedNames: const {},
      );

      expect(result.first.productName, 'Lait bio');
      expect(result.first.frequency, greaterThan(0));
    });

    test('les produits fréquents passent avant le catalogue local', () {
      final history = [
        _record('Compote maison', 8, GroceryCategory.grocery),
        _record('Compote poire', 5, GroceryCategory.grocery),
      ];

      final result = buildSuggestions(
        sortedHistory: history,
        query: 'comp',
        excludedNames: const {},
      );

      expect(result.first.productName, 'Compote maison');
      expect(result[1].productName, 'Compote poire');
      expect(result.any((s) => s.productName == 'Compote'), isTrue);
    });

    test('reprise de la quantité et catégorie habituelles', () {
      final history = [
        _record('Lait', 3, GroceryCategory.fresh, quantity: 2),
      ];

      final result = buildSuggestions(
        sortedHistory: history,
        query: 'la',
        excludedNames: const {},
      );

      expect(result.first.productName, 'Lait');
      expect(result.first.quantity, 2);
      expect(result.first.category, GroceryCategory.fresh);
    });
  });

  group('buildSuggestions - exclusions et limites', () {
    test('produit déjà dans la liste exclu des suggestions', () {
      final history = [_record('Lait', 5, GroceryCategory.fresh)];

      final result = buildSuggestions(
        sortedHistory: history,
        query: 'la',
        excludedNames: const {'lait'},
      );

      expect(result.any((s) => s.productName == 'Lait'), isFalse);
    });

    test('produit exclu absent également du catalogue', () {
      final result = buildSuggestions(
        sortedHistory: const [],
        query: 'lait',
        excludedNames: const {'lait'},
      );

      expect(result.any((s) => s.productName == 'Lait'), isFalse);
    });

    test('suggestions limitées à 5 au maximum', () {
      final history = List.generate(
        10,
        (index) => _record(
          'Produit $index',
          10 - index,
          GroceryCategory.other,
        ),
      );

      final result = buildSuggestions(
        sortedHistory: history,
        query: 'produit',
        excludedNames: const {},
      );

      expect(result.length, lessThanOrEqualTo(5));
    });
  });

  group('buildSuggestions - requête vide', () {
    test('requête vide retourne uniquement les entrées historique', () {
      final history = [_record('Lait', 5, GroceryCategory.fresh)];

      final result = buildSuggestions(
        sortedHistory: history,
        query: '',
        excludedNames: const {},
      );

      expect(result.every((suggestion) => suggestion.frequency > 0), isTrue);
    });

    test('requête vide sans historique retourne liste vide', () {
      final result = buildSuggestions(
        sortedHistory: const [],
        query: '',
        excludedNames: const {},
      );

      expect(result, isEmpty);
    });
  });
}
