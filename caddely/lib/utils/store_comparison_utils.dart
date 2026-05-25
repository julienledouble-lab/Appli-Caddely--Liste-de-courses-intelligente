import '../models/store.dart';
import '../models/store_basket.dart';
import '../models/store_comparison_result.dart';

const usefulSavingsAmountThreshold = 3.0;
const usefulSavingsPercentThreshold = 0.10;

StoreComparisonResult buildStoreComparisonResult({
  required List<StoreBasket> allBaskets,
  required List<Store> selectedStores,
  required Store? primaryStore,
}) {
  final selectedIds = selectedStores.map((store) => store.id).toSet();
  final baskets = allBaskets
      .where((basket) => selectedIds.contains(basket.storeId))
      .toList()
    ..sort((a, b) => a.totalPrice.compareTo(b.totalPrice));

  final cheapest = baskets.first;
  final primaryBasket = primaryStore == null
      ? null
      : baskets.where((basket) => basket.storeId == primaryStore.id).firstOrNull;
  final savingsVsPrimary = primaryBasket == null
      ? 0.0
      : (primaryBasket.totalPrice - cheapest.totalPrice)
          .clamp(0.0, double.infinity)
          .toDouble();
  final useful = primaryBasket == null
      ? false
      : isUsefulSavings(
          savings: savingsVsPrimary,
          primaryBasketTotal: primaryBasket.totalPrice,
        );
  final primaryBest = primaryBasket != null && primaryBasket.storeId == cheapest.storeId;

  return StoreComparisonResult(
    baskets: baskets,
    cheapest: cheapest,
    primaryBasket: primaryBasket,
    savingsVsPrimary: savingsVsPrimary,
    isUsefulSavings: useful,
    isPrimaryBestChoice: primaryBest,
    message: buildComparisonMessage(
      primaryStore: primaryStore,
      primaryBasket: primaryBasket,
      cheapestBasket: cheapest,
      savingsVsPrimary: savingsVsPrimary,
      isUsefulSavings: useful,
      isPrimaryBestChoice: primaryBest,
    ),
  );
}

bool isUsefulSavings({
  required double savings,
  required double primaryBasketTotal,
}) {
  if (savings <= 0 || primaryBasketTotal <= 0) {
    return false;
  }

  return savings >= usefulSavingsAmountThreshold ||
      savings / primaryBasketTotal >= usefulSavingsPercentThreshold;
}

String buildComparisonMessage({
  required Store? primaryStore,
  required StoreBasket? primaryBasket,
  required StoreBasket cheapestBasket,
  required double savingsVsPrimary,
  required bool isUsefulSavings,
  required bool isPrimaryBestChoice,
}) {
  if (primaryStore == null || primaryBasket == null) {
    return 'Choisis ton magasin habituel pour contextualiser les \u00E9conomies.';
  }

  if (isPrimaryBestChoice) {
    return 'Ton magasin habituel est le meilleur choix pour cette liste.';
  }

  if (isUsefulSavings) {
    return 'Tu peux \u00E9conomiser ${savingsVsPrimary.toStringAsFixed(2)} \u20AC par rapport \u00E0 ton magasin habituel.';
  }

  return 'L\'\u00E9cart est faible : pas forc\u00E9ment utile de changer de magasin.';
}
