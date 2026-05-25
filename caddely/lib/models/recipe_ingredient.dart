import 'dart:convert';

import 'grocery_category.dart';
import '../utils/recipe_ingredient_format_utils.dart';

class RecipeIngredient {
  final String name;
  final double? quantity;
  final String unit;
  final GroceryCategory category;
  final bool isSelected;

  const RecipeIngredient({
    required this.name,
    this.quantity,
    this.unit = '',
    this.category = GroceryCategory.other,
    this.isSelected = true,
  });

  RecipeIngredient copyWith({
    String? name,
    double? quantity,
    bool clearQuantity = false,
    String? unit,
    GroceryCategory? category,
    bool? isSelected,
  }) {
    return RecipeIngredient(
      name: name ?? this.name,
      quantity: clearQuantity ? null : (quantity ?? this.quantity),
      unit: unit ?? this.unit,
      category: category ?? this.category,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  String get quantityLabel {
    return formatRecipeIngredientAmount(
      quantity: quantity,
      unit: unit,
    );
  }

  bool get isCountableUnit {
    final normalizedUnit = unit.trim().toLowerCase();
    return normalizedUnit.isEmpty ||
        normalizedUnit == 'piece' ||
        normalizedUnit == 'pieces' ||
        normalizedUnit == 'pi\u00E8ce' ||
        normalizedUnit == 'pi\u00E8ces' ||
        normalizedUnit == 'filet' ||
        normalizedUnit == 'filets';
  }

  int get groceryQuantity {
    if (quantity == null || !isCountableUnit) {
      return 1;
    }

    final rounded = quantity!.round();
    return rounded < 1 ? 1 : rounded;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'category': category.storageKey,
        'isSelected': isSelected,
      };

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    final quantityValue = json['quantity'];
    return RecipeIngredient(
      name: json['name'] as String,
      quantity: quantityValue is num ? quantityValue.toDouble() : null,
      unit: json['unit'] as String? ?? '',
      category: groceryCategoryFromStorage(json['category'] as String?),
      isSelected: json['isSelected'] as bool? ?? true,
    );
  }

  static List<RecipeIngredient> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((entry) => RecipeIngredient.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<RecipeIngredient> ingredients) {
    return jsonEncode(ingredients.map((entry) => entry.toJson()).toList());
  }
}
