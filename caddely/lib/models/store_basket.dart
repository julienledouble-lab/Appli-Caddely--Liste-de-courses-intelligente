class StoreBasket {
  final String storeId;
  final String storeName;
  final String storeEmoji;
  final double totalPrice;
  final List<StoreItemPrice> itemPrices;

  const StoreBasket({
    required this.storeId,
    required this.storeName,
    required this.storeEmoji,
    required this.totalPrice,
    required this.itemPrices,
  });
}

class StoreItemPrice {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const StoreItemPrice({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });
}
