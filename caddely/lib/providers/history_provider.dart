import 'package:flutter/foundation.dart';
import '../models/grocery_category.dart';
import '../models/habit_suggestion.dart';
import '../models/purchase_record.dart';
import '../services/storage_service.dart';
import '../utils/history_utils.dart';
import '../utils/product_name_utils.dart';

class HistoryProvider extends ChangeNotifier {
  final StorageService _storage;
  static const Duration duplicateWindow = Duration(minutes: 2);

  List<PurchaseRecord> _records = [];

  HistoryProvider(this._storage);

  List<PurchaseRecord> get records => List.unmodifiable(_records);
  List<PurchaseRecord> get topProducts => sortedByFrequency.take(5).toList();
  List<PurchaseRecord> get recentProducts =>
      _records.where((record) => record.isRecent).toList()
        ..sort((a, b) => b.lastPurchasedAt.compareTo(a.lastPurchasedAt));
  List<PurchaseRecord> get habitProducts =>
      _records.where((record) => record.isHabit).toList()
        ..sort((a, b) => b.purchaseCount.compareTo(a.purchaseCount));

  List<PurchaseRecord> get sortedByFrequency {
    final sorted = List<PurchaseRecord>.from(_records);
    sorted.sort((a, b) {
      final frequency = b.purchaseCount.compareTo(a.purchaseCount);
      if (frequency != 0) return frequency;
      return b.lastPurchasedAt.compareTo(a.lastPurchasedAt);
    });
    return sorted;
  }

  Set<String> get habitProductNames => _records
      .where((record) => record.isFrequent)
      .map((record) => normalizeProductName(record.productName))
      .toSet();

  Future<void> load() async {
    _records = _mergeDuplicateRecords(await _storage.loadHistory());
    await _storage.saveHistory(_records);
    notifyListeners();
  }

  Future<void> recordPurchase(
    String productName, {
    required int quantity,
    required GroceryCategory category,
    DateTime? now,
  }) async {
    final cleaned = cleanProductName(productName);
    if (cleaned.isEmpty) return;

    final purchaseTime = now ?? DateTime.now();
    final normalized = normalizeProductName(cleaned);
    final index = _records.indexWhere(
      (record) => normalizeProductName(record.productName) == normalized,
    );

    if (index != -1) {
      final existing = _records[index];
      if (shouldIgnoreRepeatedPurchase(
        now: purchaseTime,
        lastPurchasedAt: existing.lastPurchasedAt,
        duplicateWindow: duplicateWindow,
      )) {
        return;
      }

      existing.purchaseCount++;
      existing.lastPurchasedAt = purchaseTime;
      existing.registerPreference(quantity: quantity, category: category);
    } else {
      final record = PurchaseRecord(
        productName: cleaned,
        purchaseCount: 1,
        lastPurchasedAt: purchaseTime,
        quantityStats: { '${quantity < 1 ? 1 : quantity}': 1 },
        categoryStats: { category.storageKey: 1 },
      );
      _records.add(record);
    }

    await _storage.saveHistory(_records);
    notifyListeners();
  }

  bool isHabitProduct(String productName) {
    final normalized = normalizeProductName(productName);
    return _records.any(
      (record) =>
          normalizeProductName(record.productName) == normalized &&
          record.isFrequent,
    );
  }

  List<HabitSuggestion> suggestionsForQuery({
    required String query,
    required Set<String> excludedNames,
    int limit = 4,
  }) {
    final trimmedQuery = query.trim();
    final matches = sortedByFrequency.where((record) {
      final normalizedName = normalizeProductName(record.productName);
      if (excludedNames.contains(normalizedName)) {
        return false;
      }

      return trimmedQuery.isEmpty || productMatches(record.productName, trimmedQuery);
    }).take(limit);

    return matches.map(HabitSuggestion.fromRecord).toList();
  }

  List<PurchaseRecord> _mergeDuplicateRecords(List<PurchaseRecord> source) {
    final merged = <String, PurchaseRecord>{};

    for (final record in source) {
      final cleanedName = cleanProductName(record.productName);
      if (cleanedName.isEmpty) {
        continue;
      }

      final key = normalizeProductName(cleanedName);
      final existing = merged[key];
      if (existing == null) {
        merged[key] = PurchaseRecord(
          productName: cleanedName,
          purchaseCount: record.purchaseCount,
          lastPurchasedAt: record.lastPurchasedAt,
          quantityStats: Map<String, int>.from(record.quantityStats),
          categoryStats: Map<String, int>.from(record.categoryStats),
        );
        continue;
      }

      existing.purchaseCount += record.purchaseCount;
      if (record.lastPurchasedAt.isAfter(existing.lastPurchasedAt)) {
        existing.lastPurchasedAt = record.lastPurchasedAt;
      }
      for (final entry in record.quantityStats.entries) {
        existing.quantityStats.update(
          entry.key,
          (value) => value + entry.value,
          ifAbsent: () => entry.value,
        );
      }
      for (final entry in record.categoryStats.entries) {
        existing.categoryStats.update(
          entry.key,
          (value) => value + entry.value,
          ifAbsent: () => entry.value,
        );
      }
    }

    return merged.values.toList()
      ..sort((a, b) => b.purchaseCount.compareTo(a.purchaseCount));
  }
}
