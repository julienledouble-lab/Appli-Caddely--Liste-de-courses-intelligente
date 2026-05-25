class Promo {
  final String id;
  final String productName;
  final String storeId;
  final String storeName;
  final double? originalPrice;
  final double? promoPrice;
  final String? discountLabel;
  final DateTime validUntil;

  const Promo({
    required this.id,
    required this.productName,
    required this.storeId,
    required this.storeName,
    this.originalPrice,
    this.promoPrice,
    this.discountLabel,
    required this.validUntil,
  });

  double? get savings => (originalPrice != null && promoPrice != null)
      ? originalPrice! - promoPrice!
      : null;

  double? get discountPercent =>
      (savings != null && originalPrice != null && originalPrice! > 0)
          ? (savings! / originalPrice!) * 100
          : null;

  String get priceLabel {
    if (discountLabel != null) {
      return discountLabel!;
    }
    if (promoPrice != null && originalPrice != null) {
      return '${promoPrice!.toStringAsFixed(2)} € au lieu de ${originalPrice!.toStringAsFixed(2)} €';
    }
    return '';
  }
}
