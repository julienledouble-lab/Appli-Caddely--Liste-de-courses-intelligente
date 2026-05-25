import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/utils/product_icon_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('productIconFor', () {
    test('associe une icône spécifique à un produit connu', () {
      final icon = productIconFor(
        productName: 'Café',
        category: GroceryCategory.grocery,
      );

      expect(icon, Icons.coffee_outlined);
    });

    test('associe une icône spécifique à Shampooing', () {
      final icon = productIconFor(
        productName: 'Shampooing',
        category: GroceryCategory.hygiene,
      );

      expect(icon, Icons.soap_outlined);
    });

    test('retombe sur une icône de catégorie si le produit est inconnu', () {
      final icon = productIconFor(
        productName: 'Produit mystère',
        category: GroceryCategory.home,
      );

      expect(icon, fallbackIconForCategory(GroceryCategory.home));
    });
  });
}
