import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/models/recipe_ingredient.dart';
import 'package:caddely/utils/recipe_ingredient_format_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats simple fractions for display', () {
    expect(formatRecipeIngredientQuantity(0.5), '1/2');
    expect(formatRecipeIngredientQuantity(0.25), '1/4');
    expect(formatRecipeIngredientQuantity(0.75), '3/4');
    expect(formatRecipeIngredientQuantity(1.0), '1');
    expect(formatRecipeIngredientQuantity(2.0), '2');
  });

  test('cleans common recipe units', () {
    expect(formatRecipeIngredientUnit('sachet(s)', quantity: 0.5), 'sachet');
    expect(formatRecipeIngredientUnit('pincee(s)', quantity: 0.5), 'pincée');
    expect(formatRecipeIngredientUnit('c. a soupe(s)', quantity: 1), 'c. à soupe');
    expect(formatRecipeIngredientUnit('c. a cafe(s)', quantity: 1), 'c. à café');
    expect(formatRecipeIngredientUnit('g', quantity: 200), 'g');
  });

  test('cleans common ingredient names', () {
    expect(formatRecipeIngredientName('Oeuf(s)', quantity: 2), 'Œufs');
    expect(formatRecipeIngredientName('oeuf(s)', quantity: 2), 'Œufs');
    expect(formatRecipeIngredientName('Oeuf', quantity: 1), 'Œuf');
    expect(formatRecipeIngredientName('creme fraiche', quantity: 1), 'Crème fraîche');
    expect(formatRecipeIngredientName('Sucre vanille', quantity: 1), 'Sucre vanillé');
    expect(formatRecipeIngredientName('Pates', quantity: 1), 'Pâtes');
    expect(formatRecipeIngredientName('cafe', quantity: 1), 'Café');
  });

  test('builds a clean final ingredient label', () {
    const ingredient = RecipeIngredient(
      name: 'Oeuf(s)',
      quantity: 2,
      unit: '',
      category: GroceryCategory.fresh,
    );

    expect(
      formatRecipeIngredientLabel(
        name: ingredient.name,
        quantity: ingredient.quantity,
        unit: ingredient.unit,
      ),
      '2 Œufs',
    );
  });

  test('builds a clean amount for half sachet', () {
    const ingredient = RecipeIngredient(
      name: 'Sucre vanille',
      quantity: 0.5,
      unit: 'sachet(s)',
      category: GroceryCategory.grocery,
    );

    expect(
      formatRecipeIngredientAmount(
        quantity: ingredient.quantity,
        unit: ingredient.unit,
      ),
      '1/2 sachet',
    );
    expect(
      formatRecipeIngredientLabel(
        name: ingredient.name,
        quantity: ingredient.quantity,
        unit: ingredient.unit,
      ),
      '1/2 sachet Sucre vanillé',
    );
  });
}
