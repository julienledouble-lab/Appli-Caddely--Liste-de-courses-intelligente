enum GroceryCategory {
  fruitsAndVegetables,
  fresh,
  grocery,
  drinks,
  hygiene,
  home,
  frozen,
  other,
}

extension GroceryCategoryX on GroceryCategory {
  String get label => switch (this) {
        GroceryCategory.fruitsAndVegetables => 'Fruits & l\u00E9gumes',
        GroceryCategory.fresh => 'Frais',
        GroceryCategory.grocery => '\u00C9picerie',
        GroceryCategory.drinks => 'Boissons',
        GroceryCategory.hygiene => 'Hygi\u00E8ne',
        GroceryCategory.home => 'Maison',
        GroceryCategory.frozen => 'Surgel\u00E9s',
        GroceryCategory.other => 'Autre',
      };

  String get storageKey => switch (this) {
        GroceryCategory.fruitsAndVegetables => 'fruits_and_vegetables',
        GroceryCategory.fresh => 'fresh',
        GroceryCategory.grocery => 'grocery',
        GroceryCategory.drinks => 'drinks',
        GroceryCategory.hygiene => 'hygiene',
        GroceryCategory.home => 'home',
        GroceryCategory.frozen => 'frozen',
        GroceryCategory.other => 'other',
      };
}

GroceryCategory groceryCategoryFromStorage(String? value) {
  return GroceryCategory.values.firstWhere(
    (category) => category.storageKey == value,
    orElse: () => GroceryCategory.other,
  );
}
