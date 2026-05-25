import 'grocery_category.dart';
import 'purchase_record.dart';

class HabitSuggestion {
  final String productName;
  final int quantity;
  final GroceryCategory category;
  final int frequency;

  const HabitSuggestion({
    required this.productName,
    required this.quantity,
    required this.category,
    required this.frequency,
  });

  factory HabitSuggestion.fromRecord(PurchaseRecord record) {
    return HabitSuggestion(
      productName: record.productName,
      quantity: record.preferredQuantity,
      category: record.preferredCategory,
      frequency: record.purchaseCount,
    );
  }
}
