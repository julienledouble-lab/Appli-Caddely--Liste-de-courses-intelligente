import 'grocery_item.dart';
import 'promo.dart';

enum PromoReason {
  inCurrentList,
  habitualProduct,
  inCurrentListAndHabitual,
}

enum PromoStorePriority {
  primary,
  secondary,
  other,
}

enum PromoFilter {
  all,
  myStore,
  comparedStores,
}

class PromoInsight {
  final Promo promo;
  final PromoReason reason;
  final PromoStorePriority storePriority;
  final GroceryItem? matchingListItem;
  final bool isHabitProduct;

  const PromoInsight({
    required this.promo,
    required this.reason,
    required this.storePriority,
    required this.matchingListItem,
    required this.isHabitProduct,
  });

  bool get isInCurrentList => matchingListItem != null;
  int? get quantityInList => matchingListItem?.quantity;
  double? get unitSavings => promo.savings;
  double? get estimatedSavings =>
      unitSavings == null || quantityInList == null ? null : unitSavings! * quantityInList!;

  String get reasonLabel => switch (reason) {
        PromoReason.inCurrentList => 'Dans ta liste actuelle',
        PromoReason.habitualProduct => 'Produit habituel',
        PromoReason.inCurrentListAndHabitual =>
          'Dans ta liste et produit habituel',
      };
}

class PromoSummary {
  final int totalCount;
  final int primaryStoreCount;

  const PromoSummary({
    required this.totalCount,
    required this.primaryStoreCount,
  });

  String summaryLabel({required bool hasPrimaryStore}) {
    if (totalCount == 0) {
      return 'Aucune promo utile pour le moment.';
    }

    if (hasPrimaryStore && primaryStoreCount > 0) {
      return '$primaryStoreCount promo${primaryStoreCount > 1 ? 's' : ''} concerne${primaryStoreCount > 1 ? 'nt' : ''} ton magasin habituel.';
    }

    return '$totalCount promo${totalCount > 1 ? 's' : ''} utile${totalCount > 1 ? 's' : ''} repérée${totalCount > 1 ? 's' : ''} pour ta liste.';
  }
}
