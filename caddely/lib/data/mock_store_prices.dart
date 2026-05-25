import '../models/grocery_item.dart';
import '../models/store_basket.dart';
import '../utils/product_name_utils.dart';

const Map<String, Map<String, double>> _mockPriceTable = {
  'Caf\u00E9 moulu': {
    'leclerc': 3.89,
    'carrefour': 3.49,
    'intermarche': 4.10,
    'lidl': 3.35,
    'aldi': 3.20,
    'auchan': 3.99,
    'super_u': 3.75,
    'monoprix': 4.45,
  },
  'Lessive liquide': {
    'leclerc': 7.90,
    'carrefour': 8.50,
    'intermarche': 6.23,
    'lidl': 6.45,
    'aldi': 5.99,
    'auchan': 7.20,
    'super_u': 7.55,
    'monoprix': 8.95,
  },
  'Yaourts nature': {
    'leclerc': 1.49,
    'carrefour': 1.99,
    'intermarche': 1.89,
    'lidl': 1.42,
    'aldi': 1.35,
    'auchan': 1.79,
    'super_u': 1.68,
    'monoprix': 2.10,
  },
  'P\u00E2tes spaghetti': {
    'leclerc': 0.99,
    'carrefour': 1.15,
    'intermarche': 1.10,
    'lidl': 0.92,
    'aldi': 0.85,
    'auchan': 1.05,
    'super_u': 1.02,
    'monoprix': 1.45,
  },
  'Jus d\'orange': {
    'leclerc': 2.50,
    'carrefour': 2.99,
    'intermarche': 2.80,
    'lidl': 2.20,
    'aldi': 2.10,
    'auchan': 2.65,
    'super_u': 2.58,
    'monoprix': 3.15,
  },
  'Beurre doux': {
    'leclerc': 3.20,
    'carrefour': 2.99,
    'intermarche': 3.45,
    'lidl': 3.05,
    'aldi': 2.89,
    'auchan': 3.30,
    'super_u': 3.24,
    'monoprix': 3.75,
  },
  'Fromage r\u00E2p\u00E9': {
    'leclerc': 2.40,
    'carrefour': 2.65,
    'intermarche': 1.99,
    'lidl': 2.05,
    'aldi': 1.89,
    'auchan': 2.50,
    'super_u': 2.35,
    'monoprix': 2.95,
  },
  'Pain de mie': {
    'leclerc': 1.45,
    'carrefour': 1.80,
    'intermarche': 1.70,
    'lidl': 1.48,
    'aldi': 1.39,
    'auchan': 1.65,
    'super_u': 1.58,
    'monoprix': 1.95,
  },
  'Lait demi-\u00E9cr\u00E9m\u00E9': {
    'leclerc': 0.99,
    'carrefour': 1.05,
    'intermarche': 1.10,
    'lidl': 0.95,
    'aldi': 0.89,
    'auchan': 1.02,
    'super_u': 1.00,
    'monoprix': 1.25,
  },
  '\u0152ufs x6': {
    'leclerc': 1.89,
    'carrefour': 2.20,
    'intermarche': 2.10,
    'lidl': 1.82,
    'aldi': 1.75,
    'auchan': 1.99,
    'super_u': 1.94,
    'monoprix': 2.35,
  },
  'Farine': {
    'leclerc': 0.89,
    'carrefour': 1.05,
    'intermarche': 0.99,
    'lidl': 0.84,
    'aldi': 0.79,
    'auchan': 0.95,
    'super_u': 0.91,
    'monoprix': 1.19,
  },
  'Sucre': {
    'leclerc': 1.15,
    'carrefour': 1.30,
    'intermarche': 1.25,
    'lidl': 1.05,
    'aldi': 0.99,
    'auchan': 1.20,
    'super_u': 1.18,
    'monoprix': 1.45,
  },
};

const Map<String, String> _storeNames = {
  'leclerc': 'Leclerc',
  'carrefour': 'Carrefour',
  'intermarche': 'Intermarch\u00E9',
  'lidl': 'Lidl',
  'aldi': 'Aldi',
  'auchan': 'Auchan',
  'super_u': 'Super U',
  'monoprix': 'Monoprix',
};

const Map<String, String> _storeEmojis = {
  'leclerc': '\u{1F535}',
  'carrefour': '\u{1F6D2}',
  'intermarche': '\u{1F534}',
  'lidl': '\u{1F7E6}',
  'aldi': '\u{1F7E1}',
  'auchan': '\u{1F7E0}',
  'super_u': '\u{1F7E2}',
  'monoprix': '\u{1F7E3}',
};

double _fallbackPrice(String storeId) {
  const base = {
    'leclerc': 2.50,
    'carrefour': 2.95,
    'intermarche': 2.80,
    'lidl': 2.35,
    'aldi': 2.20,
    'auchan': 2.70,
    'super_u': 2.75,
    'monoprix': 3.10,
  };
  return base[storeId] ?? 2.60;
}

MapEntry<String, Map<String, double>>? _findBestPriceEntry(String productName) {
  for (final entry in _mockPriceTable.entries) {
    if (productMatches(entry.key, productName)) {
      return entry;
    }
  }

  return null;
}

double calculateLineTotal({
  required double unitPrice,
  required int quantity,
}) {
  return unitPrice * quantity;
}

List<StoreBasket> getStoreBasketsForItems(List<GroceryItem> items) {
  const storeIds = [
    'leclerc',
    'carrefour',
    'intermarche',
    'lidl',
    'aldi',
    'auchan',
    'super_u',
    'monoprix',
  ];

  return storeIds.map((storeId) {
    final itemPrices = items.map((item) {
      final priceEntry = _findBestPriceEntry(item.name);
      final matchedName = priceEntry?.key ?? cleanProductName(item.name);
      final unitPrice = priceEntry?.value[storeId] ?? _fallbackPrice(storeId);
      final totalPrice = calculateLineTotal(
        unitPrice: unitPrice,
        quantity: item.quantity,
      );

      return StoreItemPrice(
        productName: matchedName,
        quantity: item.quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
      );
    }).toList();

    final total = itemPrices.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    return StoreBasket(
      storeId: storeId,
      storeName: _storeNames[storeId] ?? storeId,
      storeEmoji: _storeEmojis[storeId] ?? '\u{1F3EA}',
      totalPrice: total,
      itemPrices: itemPrices,
    );
  }).toList();
}
