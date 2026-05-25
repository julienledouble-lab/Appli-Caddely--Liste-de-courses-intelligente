import 'dart:convert';
import 'grocery_category.dart';

class GroceryItem {
  final String id;
  String name;
  int quantity;
  GroceryCategory category;
  bool isPicked;
  final DateTime addedAt;

  GroceryItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.category = GroceryCategory.other,
    this.isPicked = false,
    required this.addedAt,
  });

  GroceryItem copyWith({
    String? name,
    int? quantity,
    GroceryCategory? category,
    bool? isPicked,
  }) {
    return GroceryItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      isPicked: isPicked ?? this.isPicked,
      addedAt: addedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'category': category.storageKey,
        'isPicked': isPicked,
        'addedAt': addedAt.toIso8601String(),
      };

  factory GroceryItem.fromJson(Map<String, dynamic> json) => GroceryItem(
        id: json['id'] as String,
        name: json['name'] as String,
        quantity: (json['quantity'] as int?) ?? 1,
        category: groceryCategoryFromStorage(json['category'] as String?),
        isPicked: json['isPicked'] as bool? ?? false,
        addedAt: DateTime.parse(json['addedAt'] as String),
      );

  static List<GroceryItem> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((entry) => GroceryItem.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<GroceryItem> items) {
    return jsonEncode(items.map((entry) => entry.toJson()).toList());
  }
}
