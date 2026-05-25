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
  group('buildSuggestions — catalogue local (historique vide)', () {
    test('"la" propose "Lait" depuis le catalogue', () {
      final result = buildSuggestions(
        sortedHistory: [],
        query: 'la',
        excludedNames: {},
      );
      expect(result.any((s) => s.productName == 'Lait'), isTrue);
    });

    test('"caf" propose "Café" depuis le catalogue', () {
      final result = buildSuggestions(
        sortedHistory: [],
        query: 'caf',
        excludedNames: {},
      );
      expect(result.any((s) => s.productName == 'Café'), isTrue);
    });

    test('"pate" propose "Pâtes" grâce à la normalisation des accents', () {
      final result = buildSuggestions(
        sortedHistory: [],
        query: 'pate',
        excludedNames: {},
      );
      expect(result.any((s) => s.productName == 'Pâtes'), isTrue);
    });

    test('"less" propose "Lessive" depuis le catalogue', () {
      final result = buildSuggestions(
        sortedHistory: [],
        query: 'less',
        excludedNames: {},
      );
      expect(result.any((s) => s.productName == 'Lessive'), isTrue);
    });

    test('les suggestions du catalogue ont frequency == 0', () {
      final result = buildSuggestions(
        sortedHistory: [],
        query: 'lait',
        excludedNames: {},
      );
      expect(result.isNotEmpty, isTrue);
      expect(result.every((s) => s.frequency == 0), isTrue);
    });
  });

  group('buildSuggestions — historique prioritaire', () {
    test("l'historique passe avant le catalogue", () {
      final history = [_record('Lait bio', 3, GroceryCategory.fresh, quantity: 2)];
      final result = buildSuggestions(
        sortedHistory: history,
        query: 'lait',
        excludedNames: {},
      );
      expect(result.first.productName, 'Lait bio');
      expect(result.first.frequency, greaterThan(0));
    });

    test('les produits fréquents passent avant les moins fréquents', () {
      // On passe une liste pré-triée par fréquence décroissante
      final history = [
        _record('Café', 8, GroceryCategory.drinks),
        _record('Lait', 5, GroceryCategory.fresh),
        _record('Yaourts', 2, GroceryCategory.fresh),
      ];
      final result = buildSuggestions(
        sortedHistory: history,
        query: '',
        excludedNames: {},
      );
      expect(result[0].productName, 'Café');
      expect(result[1].productName, 'Lait');
      expect(result[2].productName, 'Yaourts');
    });

    test('reprise de la quantité et catégorie habituelles', () {
      final history = [_record('Lait', 3, GroceryCategory.fresh, quantity: 2)];
      final result = buildSuggestions(
        sortedHistory: history,
        query: 'la',
        excludedNames: {},
      );
      expect(result.first.productName, 'Lait');
      expect(result.first.quantity, 2);
      expect(result.first.category, GroceryCategory.fresh);
    });
  });

  group('buildSuggestions — exclusions et limites', () {
    test('produit déjà dans la liste exclu des suggestions', () {
      final history = [_record('Lait', 5, GroceryCategory.fresh)];
      final result = buildSuggestions(
        sortedHistory: history,
        query: 'la',
        excludedNames: {'lait'},
      );
      expect(result.any((s) => s.productName == 'Lait'), isFalse);
    });

    test('produit exclu absent également du catalogue', () {
      final result = buildSuggestions(
        sortedHistory: [],
        query: 'lait',
        excludedNames: {'lait'},
      );
      expect(result.any((s) => s.productName == 'Lait'), isFalse);
    });

    test('suggestions limitées à 5 au maximum', () {
      final history = List.generate(
        10,
        (i) => _record('Produit $i', 10 - i, GroceryCategory.other),
      );
      final result = buildSuggestions(
        sortedHistory: history,
        query: 'produit',
        excludedNames: {},
      );
      expect(result.length, lessThanOrEqualTo(5));
    });

    test('limit personnalisé respecté', () {
      final history = List.generate(
        10,
        (i) => _record('Article $i', 10 - i, GroceryCategory.other),
      );
      final result = buildSuggestions(
        sortedHistory: history,
        query: 'article',
        excludedNames: {},
        limit: 3,
      );
      expect(result.length, lessThanOrEqualTo(3));
    });
  });

  group('buildSuggestions — requête vide', () {
    test('requête vide retourne uniquement les entrées historique', () {
      final history = [_record('Lait', 5, GroceryCategory.fresh)];
      final result = buildSuggestions(
        sortedHistory: history,
        query: '',
        excludedNames: {},
      );
      // Pas de catalogue quand query est vide
      expect(result.every((s) => s.frequency > 0), isTrue);
    });

    test('requête vide sans historique retourne liste vide', () {
      final result = buildSuggestions(
        sortedHistory: [],
        query: '',
        excludedNames: {},
      );
      expect(result, isEmpty);
    });
  });
}
