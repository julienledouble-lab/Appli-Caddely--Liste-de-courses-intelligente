import 'package:caddely/utils/product_name_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeProductName trims, collapses spaces and lowercases', () {
    expect(normalizeProductName('  Lait   Demi-écrémé  '), 'lait demi-écrémé');
  });

  group('stripAccents', () {
    test('supprime les accents courants du français', () {
      expect(stripAccents('éàâùîœç'), 'eaauioec');
    });

    test('laisse les caractères sans accent inchangés', () {
      expect(stripAccents('lait pain'), 'lait pain');
    });

    test('convertit æ en ae et œ en oe', () {
      expect(stripAccents('œufs'), 'oeufs');
      expect(stripAccents('pæan'), 'paean');
    });
  });

  group('normalizeForSearch', () {
    test('lowercase + suppression accents', () {
      expect(normalizeForSearch('Pâtes'), 'pates');
      expect(normalizeForSearch('CAFÉ'), 'cafe');
      expect(normalizeForSearch('Crème fraîche'), 'creme fraiche');
    });
  });

  group('productMatches (accent-insensible)', () {
    test('"caf" correspond à "Café"', () {
      expect(productMatches('Café', 'caf'), isTrue);
    });

    test('"pate" correspond à "Pâtes"', () {
      expect(productMatches('Pâtes', 'pate'), isTrue);
    });

    test('"la" correspond à "Lait"', () {
      expect(productMatches('Lait', 'la'), isTrue);
    });

    test('"less" correspond à "Lessive"', () {
      expect(productMatches('Lessive', 'less'), isTrue);
    });

    test('"ya" correspond à "Yaourts"', () {
      expect(productMatches('Yaourts', 'ya'), isTrue);
    });

    test('requête vide retourne false', () {
      expect(productMatches('Lait', ''), isFalse);
    });

    test('candidat sans rapport ne correspond pas', () {
      expect(productMatches('Fromage', 'lait'), isFalse);
    });
  });
}
