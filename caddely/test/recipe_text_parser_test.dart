import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/utils/recipe_text_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a structured recipe with ingredients and preparation', () {
    final parser = RecipeTextParser();

    final recipe = parser.parse('''
Pates au poulet cremeux
Pour 4 personnes
Preparation : 15 min
Cuisson : 20 min
Ingredients
200 g de pates
2 filets de poulet
20 cl de creme fraiche
1 oignon
Sel
Poivre
Preparation
1. Faites cuire les pates.
2. Faites revenir l'oignon.
3. Ajoutez le poulet.
''');

    expect(recipe.title, 'Pates au poulet cremeux');
    expect(recipe.servings, 4);
    expect(recipe.prepTimeMinutes, 15);
    expect(recipe.cookTimeMinutes, 20);
    expect(recipe.ingredients.map((entry) => entry.name), [
      'Pates',
      'Poulet',
      'Creme fraiche',
      'Oignon',
      'Sel',
      'Poivre',
    ]);
    expect(recipe.steps, [
      'Faites cuire les pates.',
      'Faites revenir l\'oignon.',
      'Ajoutez le poulet.',
    ]);
  });

  test('keeps ingredients and steps separated across merged OCR blocks', () {
    final parser = RecipeTextParser();

    final recipe = parser.parse('''
Gratin facile
Image 1
Liste des ingredients
500 g de pommes de terre
20 cl de creme
100 g de fromage rape

Image 2
Preparation de la recette
1. Prechauffez le four a 180 degres.
2. Coupez les pommes de terre.
3. Versez la creme et enfournez.
''');

    expect(recipe.title, 'Gratin facile');
    expect(recipe.ingredients.map((entry) => entry.name), [
      'Pommes de terre',
      'Creme',
      'Fromage rape',
    ]);
    expect(recipe.steps, [
      'Prechauffez le four a 180 degres.',
      'Coupez les pommes de terre.',
      'Versez la creme et enfournez.',
    ]);
  });

  test('ignores noisy OCR lines like newsletter, calories and difficulty', () {
    final parser = RecipeTextParser();

    final recipe = parser.parse('''
Cake sale
Tres facile
Bon marche
Calories : 420 kcal
Newsletter
Il vous faut
200 g de farine
3 oeufs
100 ml de lait
Instructions
Melangez tous les ingredients.
Versez dans un moule.
Servez tiede.
''');

    expect(recipe.title, 'Cake sale');
    expect(recipe.ingredients, hasLength(3));
    expect(recipe.ingredients.first.name, 'Farine');
    expect(recipe.steps, [
      'Melangez tous les ingredients.',
      'Versez dans un moule.',
      'Servez tiede.',
    ]);
    expect(recipe.steps.join(' '), isNot(contains('Newsletter')));
  });

  test('detects ingredients without ingredient heading when quantities are present', () {
    final parser = RecipeTextParser();

    final recipe = parser.parse('''
Soupe rapide
Pour 2 pers.
2 carottes
1 oignon
500 ml d'eau
Faites cuire 20 min.
Mixez puis servez.
''');

    expect(recipe.title, 'Soupe rapide');
    expect(recipe.servings, 2);
    expect(recipe.ingredients.map((entry) => entry.name), [
      'Carottes',
      'Oignon',
      'Eau',
    ]);
    expect(recipe.steps, [
      'Faites cuire 20 min.',
      'Mixez puis servez.',
    ]);
  });

  test('extracts quantities, units and numbered steps more cleanly', () {
    final parser = RecipeTextParser();

    final recipe = parser.parse('''
Recette
Cote ingredients
1/2 sachet de levure
2 filets de poulet
Huile d'olive
Etapes
Etape 1
Coupez le poulet.
2. Faites chauffer l'huile.
3. Servez chaud.
''');

    expect(recipe.ingredients, hasLength(3));
    expect(recipe.ingredients[0].name, 'Levure');
    expect(recipe.ingredients[0].quantity, 0.5);
    expect(recipe.ingredients[0].unit, 'sachet');
    expect(recipe.ingredients[1].name, 'Poulet');
    expect(recipe.ingredients[1].quantity, 2);
    expect(recipe.ingredients[1].unit, 'filets');
    expect(recipe.ingredients[2].name, 'Huile d\'olive');
    expect(recipe.ingredients[2].category, GroceryCategory.grocery);
    expect(recipe.steps, [
      'Coupez le poulet.',
      'Faites chauffer l\'huile.',
      'Servez chaud.',
    ]);
  });

  test('never crashes and falls back to a reviewable recipe when text is ambiguous', () {
    final parser = RecipeTextParser();

    final recipe = parser.parse('''
Partager
Imprimer
Recette
''');

    expect(recipe.title, 'Recette importee');
    expect(recipe.steps, isNotEmpty);
  });
}
