import 'dart:convert';
import 'grocery_category.dart';

class PurchaseRecord {
  final String productName;
  int purchaseCount;
  DateTime lastPurchasedAt;
  final Map<String, int> quantityStats;
  final Map<String, int> categoryStats;

  PurchaseRecord({
    required this.productName,
    required this.purchaseCount,
    required this.lastPurchasedAt,
    Map<String, int>? quantityStats,
    Map<String, int>? categoryStats,
  })  : quantityStats = quantityStats ?? {'1': 1},
        categoryStats = categoryStats ?? {GroceryCategory.other.storageKey: 1};

  bool get isHabit => purchaseCount >= 5;
  bool get isFrequent => purchaseCount >= 3;
  bool get isRecent => DateTime.now().difference(lastPurchasedAt).inDays <= 10;

  int get preferredQuantity => _bestEntry(quantityStats, fallback: '1').keyAsInt;

  GroceryCategory get preferredCategory => groceryCategoryFromStorage(
        _bestEntry(
          categoryStats,
          fallback: GroceryCategory.other.storageKey,
        ).key,
      );

  String get habitLabel {
    if (isHabit) return 'Produit habituel';
    if (isRecent) return 'Acheté récemment';
    if (isFrequent) return 'Fréquent';
    return 'Occasionnel';
  }

  void registerPreference({
    required int quantity,
    required GroceryCategory category,
  }) {
    final safeQuantity = quantity < 1 ? 1 : quantity;
    quantityStats.update(
      '$safeQuantity',
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    categoryStats.update(
      category.storageKey,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'productName': productName,
        'purchaseCount': purchaseCount,
        'lastPurchasedAt': lastPurchasedAt.toIso8601String(),
        'quantityStats': quantityStats,
        'categoryStats': categoryStats,
      };

  factory PurchaseRecord.fromJson(Map<String, dynamic> json) => PurchaseRecord(
        productName: json['productName'] as String,
        purchaseCount: json['purchaseCount'] as int? ?? 1,
        lastPurchasedAt: DateTime.parse(json['lastPurchasedAt'] as String),
        quantityStats: _parseStats(json['quantityStats']),
        categoryStats: _parseStats(json['categoryStats']),
      );

  static List<PurchaseRecord> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((entry) => PurchaseRecord.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<PurchaseRecord> records) {
    return jsonEncode(records.map((entry) => entry.toJson()).toList());
  }

  static Map<String, int> _parseStats(dynamic source) {
    final result = <String, int>{};
    if (source is Map) {
      for (final entry in source.entries) {
        final value = entry.value;
        if (value is int) {
          result['${entry.key}'] = value;
        }
      }
    }
    return result;
  }

  static _StatEntry _bestEntry(
    Map<String, int> stats, {
    required String fallback,
  }) {
    if (stats.isEmpty) {
      return _StatEntry(fallback, 0);
    }

    final sorted = stats.entries.toList()
      ..sort((a, b) {
        final compare = b.value.compareTo(a.value);
        if (compare != 0) return compare;
        return a.key.compareTo(b.key);
      });

    return _StatEntry(sorted.first.key, sorted.first.value);
  }
}

class _StatEntry {
  final String key;
  final int value;

  const _StatEntry(this.key, this.value);

  int get keyAsInt => int.tryParse(key) ?? 1;
}
