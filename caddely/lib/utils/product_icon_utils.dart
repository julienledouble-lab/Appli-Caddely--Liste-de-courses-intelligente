import 'package:flutter/material.dart';

import '../models/grocery_category.dart';
import 'product_name_utils.dart';

IconData productIconFor({
  required String productName,
  required GroceryCategory category,
}) {
  final normalized = normalizeForSearch(productName);

  if (_matchesAny(normalized, const ['pomme', 'banane', 'orange', 'citron', 'fraise', 'raisin', 'poire', 'kiwi', 'avocat'])) {
    return Icons.local_florist_outlined;
  }

  if (_matchesAny(normalized, const ['tomate', 'concombre', 'salade', 'carotte', 'courgette', 'aubergine', 'poivron', 'oignon', 'ail', 'brocoli', 'chou', 'epinard', 'poireau', 'endive', 'radis', 'betterave', 'champignon', 'haricot'])) {
    return Icons.eco_outlined;
  }

  if (_matchesAny(normalized, const ['lait', 'eau', 'jus', 'limonade', 'sirop', 'soda', 'coca', 'the glace', 'cafe froid'])) {
    return Icons.local_drink_outlined;
  }

  if (_matchesAny(normalized, const ['oeuf', 'oeufs'])) {
    return Icons.egg_alt_outlined;
  }

  if (_matchesAny(normalized, const ['pain', 'biscotte', 'croissant', 'brioche'])) {
    return Icons.bakery_dining_outlined;
  }

  if (_matchesAny(normalized, const ['pate', 'riz', 'semoule', 'quinoa', 'farine', 'cereale', 'flocon', 'lentille', 'pois chiche', 'haricot rouge'])) {
    return Icons.lunch_dining_outlined;
  }

  if (_matchesAny(normalized, const ['cafe'])) {
    return Icons.coffee_outlined;
  }

  if (_matchesAny(normalized, const ['the', 'tisane'])) {
    return Icons.emoji_food_beverage_outlined;
  }

  if (_matchesAny(normalized, const ['shampooing', 'gel douche', 'savon', 'apres-shampooing'])) {
    return Icons.soap_outlined;
  }

  if (_matchesAny(normalized, const ['dentifrice', 'brosse a dents'])) {
    return Icons.health_and_safety_outlined;
  }

  if (_matchesAny(normalized, const ['lessive', 'adoucissant'])) {
    return Icons.local_laundry_service_outlined;
  }

  if (_matchesAny(normalized, const ['liquide vaisselle', 'nettoyant', 'eponge', 'pastille lave-vaisselle'])) {
    return Icons.cleaning_services_outlined;
  }

  if (_matchesAny(normalized, const ['papier toilette', 'essuie-tout', 'sopalin', 'mouchoir', 'papier cuisson', 'papier aluminium', 'film alimentaire', 'sac poubelle'])) {
    return Icons.inventory_2_outlined;
  }

  if (_matchesAny(normalized, const ['couche', 'lingette bebe', 'petit pot bebe', 'lait infantile'])) {
    return Icons.child_care_outlined;
  }

  if (_matchesAny(normalized, const ['croquette', 'litiere', 'patee', 'chien', 'chat'])) {
    return Icons.pets_outlined;
  }

  return fallbackIconForCategory(category);
}

IconData fallbackIconForCategory(GroceryCategory category) {
  return switch (category) {
    GroceryCategory.fruitsAndVegetables => Icons.eco_outlined,
    GroceryCategory.fresh => Icons.kitchen_outlined,
    GroceryCategory.grocery => Icons.lunch_dining_outlined,
    GroceryCategory.drinks => Icons.local_drink_outlined,
    GroceryCategory.hygiene => Icons.soap_outlined,
    GroceryCategory.home => Icons.cleaning_services_outlined,
    GroceryCategory.frozen => Icons.ac_unit_outlined,
    GroceryCategory.other => Icons.shopping_bag_outlined,
  };
}

bool _matchesAny(String normalizedName, List<String> candidates) {
  return candidates.any(normalizedName.contains);
}
