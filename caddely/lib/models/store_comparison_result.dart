import 'store_basket.dart';

class StoreComparisonResult {
  final List<StoreBasket> baskets;
  final StoreBasket cheapest;
  final StoreBasket? primaryBasket;
  final double savingsVsPrimary;
  final bool isUsefulSavings;
  final bool isPrimaryBestChoice;
  final String message;

  const StoreComparisonResult({
    required this.baskets,
    required this.cheapest,
    required this.primaryBasket,
    required this.savingsVsPrimary,
    required this.isUsefulSavings,
    required this.isPrimaryBestChoice,
    required this.message,
  });
}
