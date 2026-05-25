import '../models/grocery_category.dart';
import '../models/grocery_item.dart';

class ShoppingTripProgress {
  final int pickedCount;
  final int totalCount;

  const ShoppingTripProgress({
    required this.pickedCount,
    required this.totalCount,
  });

  int get pendingCount => totalCount - pickedCount;
  double get completionRatio => totalCount == 0 ? 0 : pickedCount / totalCount;
  int get completionPercent => (completionRatio * 100).round();
  String get summaryLabel =>
      '$pickedCount sur $totalCount produit${totalCount > 1 ? 's' : ''} pris';
}

ShoppingTripProgress buildShoppingTripProgress(List<GroceryItem> items) {
  final pickedCount = items.where((item) => item.isPicked).length;
  return ShoppingTripProgress(
    pickedCount: pickedCount,
    totalCount: items.length,
  );
}

GroceryItem? findNextItemToPick(
  Map<GroceryCategory, List<GroceryItem>> groupedPending,
) {
  for (final items in groupedPending.values) {
    if (items.isNotEmpty) {
      return items.first;
    }
  }

  return null;
}
