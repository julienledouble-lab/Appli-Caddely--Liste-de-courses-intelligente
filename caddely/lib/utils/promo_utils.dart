import '../models/grocery_item.dart';
import '../models/promo.dart';
import '../models/promo_insight.dart';
import 'product_name_utils.dart';

List<PromoInsight> buildPromoInsights({
  required Iterable<Promo> promotions,
  required Iterable<GroceryItem> currentList,
  required Iterable<String> habitualProducts,
  String? primaryStoreId,
  Set<String> secondaryStoreIds = const <String>{},
  PromoFilter filter = PromoFilter.all,
}) {
  final listItems = currentList.toList();
  final habitualNames = habitualProducts.toList();

  final insights = promotions
      .map(
        (promo) => _buildPromoInsight(
          promo: promo,
          listItems: listItems,
          habitualProducts: habitualNames,
          primaryStoreId: primaryStoreId,
          secondaryStoreIds: secondaryStoreIds,
        ),
      )
      .whereType<PromoInsight>()
      .where((insight) => _matchesFilter(insight, filter))
      .toList();

  insights.sort(_comparePromoInsights);
  return insights;
}

PromoSummary buildPromoSummary(
  List<PromoInsight> insights, {
  required bool hasPrimaryStore,
}) {
  final primaryCount = insights
      .where((insight) => insight.storePriority == PromoStorePriority.primary)
      .length;

  return PromoSummary(
    totalCount: insights.length,
    primaryStoreCount: primaryCount,
  );
}

PromoInsight? _buildPromoInsight({
  required Promo promo,
  required List<GroceryItem> listItems,
  required List<String> habitualProducts,
  required String? primaryStoreId,
  required Set<String> secondaryStoreIds,
}) {
  final matchingListItem = listItems.where((item) {
    return productMatches(item.name, promo.productName);
  }).firstOrNull;

  final isHabitProduct = habitualProducts.any(
    (name) => productMatches(name, promo.productName),
  );

  if (matchingListItem == null && !isHabitProduct) {
    return null;
  }

  final reason = switch ((matchingListItem != null, isHabitProduct)) {
    (true, true) => PromoReason.inCurrentListAndHabitual,
    (true, false) => PromoReason.inCurrentList,
    (false, true) => PromoReason.habitualProduct,
    (false, false) => PromoReason.habitualProduct,
  };

  final storePriority = _storePriority(
    promoStoreId: promo.storeId,
    primaryStoreId: primaryStoreId,
    secondaryStoreIds: secondaryStoreIds,
  );

  return PromoInsight(
    promo: promo,
    reason: reason,
    storePriority: storePriority,
    matchingListItem: matchingListItem,
    isHabitProduct: isHabitProduct,
  );
}

PromoStorePriority _storePriority({
  required String promoStoreId,
  required String? primaryStoreId,
  required Set<String> secondaryStoreIds,
}) {
  if (primaryStoreId != null && promoStoreId == primaryStoreId) {
    return PromoStorePriority.primary;
  }
  if (secondaryStoreIds.contains(promoStoreId)) {
    return PromoStorePriority.secondary;
  }
  return PromoStorePriority.other;
}

bool _matchesFilter(PromoInsight insight, PromoFilter filter) {
  return switch (filter) {
    PromoFilter.all => true,
    PromoFilter.myStore => insight.storePriority == PromoStorePriority.primary,
    PromoFilter.comparedStores =>
      insight.storePriority == PromoStorePriority.primary ||
          insight.storePriority == PromoStorePriority.secondary,
  };
}

int _comparePromoInsights(PromoInsight a, PromoInsight b) {
  final storePriority = a.storePriority.index.compareTo(b.storePriority.index);
  if (storePriority != 0) {
    return storePriority;
  }

  if (a.isInCurrentList != b.isInCurrentList) {
    return a.isInCurrentList ? -1 : 1;
  }

  final estimatedSavingsA = a.estimatedSavings ?? a.unitSavings ?? 0;
  final estimatedSavingsB = b.estimatedSavings ?? b.unitSavings ?? 0;
  final savingsCompare = estimatedSavingsB.compareTo(estimatedSavingsA);
  if (savingsCompare != 0) {
    return savingsCompare;
  }

  return a.promo.validUntil.compareTo(b.promo.validUntil);
}
