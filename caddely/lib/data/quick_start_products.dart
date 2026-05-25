import '../models/grocery_category.dart';

class QuickStartProduct {
  final String name;
  final GroceryCategory category;
  final int quantity;

  const QuickStartProduct({
    required this.name,
    required this.category,
    this.quantity = 1,
  });
}

const quickStartProducts = <QuickStartProduct>[
  QuickStartProduct(name: 'Lait', category: GroceryCategory.fresh),
  QuickStartProduct(name: 'Pain', category: GroceryCategory.grocery),
  QuickStartProduct(name: '\u0152ufs', category: GroceryCategory.fresh),
  QuickStartProduct(name: 'P\u00E2tes', category: GroceryCategory.grocery),
  QuickStartProduct(name: 'Riz', category: GroceryCategory.grocery),
  QuickStartProduct(name: 'Caf\u00E9', category: GroceryCategory.drinks),
  QuickStartProduct(name: 'Yaourts', category: GroceryCategory.fresh),
  QuickStartProduct(
    name: 'Pommes',
    category: GroceryCategory.fruitsAndVegetables,
  ),
  QuickStartProduct(name: 'Lessive', category: GroceryCategory.home),
  QuickStartProduct(
    name: 'Dentifrice',
    category: GroceryCategory.hygiene,
  ),
];
