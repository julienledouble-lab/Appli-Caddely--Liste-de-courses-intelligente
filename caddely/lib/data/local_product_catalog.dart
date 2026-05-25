import '../models/grocery_category.dart';
import 'quick_start_products.dart';

/// Catalogue local de ~40 produits courants français utilisé comme fallback
/// quand l'historique ne suffit pas pour proposer des suggestions.
const localProductCatalog = <QuickStartProduct>[
  // Frais
  QuickStartProduct(name: 'Lait', category: GroceryCategory.fresh),
  QuickStartProduct(name: 'Yaourts', category: GroceryCategory.fresh, quantity: 4),
  QuickStartProduct(name: 'Beurre', category: GroceryCategory.fresh),
  QuickStartProduct(name: 'Crème fraîche', category: GroceryCategory.fresh),
  QuickStartProduct(name: 'Fromage', category: GroceryCategory.fresh),
  QuickStartProduct(name: 'Œufs', category: GroceryCategory.fresh, quantity: 6),
  // Épicerie
  QuickStartProduct(name: 'Pain', category: GroceryCategory.grocery),
  QuickStartProduct(name: 'Pâtes', category: GroceryCategory.grocery, quantity: 2),
  QuickStartProduct(name: 'Riz', category: GroceryCategory.grocery),
  QuickStartProduct(name: 'Farine', category: GroceryCategory.grocery),
  QuickStartProduct(name: 'Sucre', category: GroceryCategory.grocery),
  QuickStartProduct(name: 'Sel', category: GroceryCategory.grocery),
  QuickStartProduct(name: 'Huile d\'olive', category: GroceryCategory.grocery),
  QuickStartProduct(name: 'Conserves de tomates', category: GroceryCategory.grocery),
  QuickStartProduct(name: 'Céréales', category: GroceryCategory.grocery),
  // Fruits & Légumes
  QuickStartProduct(name: 'Pommes', category: GroceryCategory.fruitsAndVegetables, quantity: 6),
  QuickStartProduct(name: 'Bananes', category: GroceryCategory.fruitsAndVegetables),
  QuickStartProduct(name: 'Carottes', category: GroceryCategory.fruitsAndVegetables),
  QuickStartProduct(name: 'Tomates', category: GroceryCategory.fruitsAndVegetables),
  QuickStartProduct(name: 'Salade', category: GroceryCategory.fruitsAndVegetables),
  QuickStartProduct(name: 'Courgettes', category: GroceryCategory.fruitsAndVegetables),
  QuickStartProduct(name: 'Oignons', category: GroceryCategory.fruitsAndVegetables),
  // Boissons
  QuickStartProduct(name: 'Café', category: GroceryCategory.drinks),
  QuickStartProduct(name: 'Thé', category: GroceryCategory.drinks),
  QuickStartProduct(name: 'Jus d\'orange', category: GroceryCategory.drinks),
  QuickStartProduct(name: 'Eau minérale', category: GroceryCategory.drinks, quantity: 6),
  QuickStartProduct(name: 'Bière', category: GroceryCategory.drinks),
  // Hygiène
  QuickStartProduct(name: 'Dentifrice', category: GroceryCategory.hygiene),
  QuickStartProduct(name: 'Shampoing', category: GroceryCategory.hygiene),
  QuickStartProduct(name: 'Savon', category: GroceryCategory.hygiene),
  QuickStartProduct(name: 'Déodorant', category: GroceryCategory.hygiene),
  // Maison
  QuickStartProduct(name: 'Lessive', category: GroceryCategory.home),
  QuickStartProduct(name: 'Liquide vaisselle', category: GroceryCategory.home),
  QuickStartProduct(name: 'Papier toilette', category: GroceryCategory.home, quantity: 6),
  QuickStartProduct(name: 'Essuie-tout', category: GroceryCategory.home),
  // Surgelés
  QuickStartProduct(name: 'Poisson pané', category: GroceryCategory.frozen),
  QuickStartProduct(name: 'Légumes surgelés', category: GroceryCategory.frozen),
  QuickStartProduct(name: 'Pizza', category: GroceryCategory.frozen),
];
