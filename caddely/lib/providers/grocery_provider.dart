import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/grocery_category.dart';
import '../models/grocery_item.dart';
import '../services/storage_service.dart';
import '../utils/grocery_item_utils.dart';
import '../utils/product_name_utils.dart';

enum AddItemResult { added, duplicate, empty }

enum UpdateItemResult { updated, duplicate, empty, notFound }

class GroceryProvider extends ChangeNotifier {
  final StorageService _storage;
  final _uuid = const Uuid();

  List<GroceryItem> _items = [];
  bool _isLoading = true;

  GroceryProvider(this._storage);

  bool get isLoading => _isLoading;
  List<GroceryItem> get pendingItems =>
      _items.where((item) => !item.isPicked).toList();
  List<GroceryItem> get pickedItems =>
      _items.where((item) => item.isPicked).toList();
  List<GroceryItem> get allItems => List.unmodifiable(_items);
  bool containsProductName(String name) => _items.any(
        (item) => normalizeProductName(item.name) == normalizeProductName(name),
      );

  Future<void> load() async {
    _items = mergeDuplicateGroceryItems(await _storage.loadGroceryList());
    _isLoading = false;
    await _storage.saveGroceryList(_items);
    notifyListeners();
  }

  Future<AddItemResult> addItem(
    String name, {
    int quantity = 1,
    GroceryCategory category = GroceryCategory.other,
  }) async {
    final cleaned = cleanProductName(name);
    if (cleaned.isEmpty) return AddItemResult.empty;

    final normalized = normalizeProductName(cleaned);
    final alreadyExists = _items.any(
      (item) => normalizeProductName(item.name) == normalized,
    );
    if (alreadyExists) return AddItemResult.duplicate;

    _items.insert(
      0,
      GroceryItem(
        id: _uuid.v4(),
        name: cleaned,
        quantity: quantity < 1 ? 1 : quantity,
        category: category,
        addedAt: DateTime.now(),
      ),
    );
    await _save();
    return AddItemResult.added;
  }

  Future<String?> toggleItem(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return null;

    final item = _items[index];
    _items[index] = item.copyWith(isPicked: !item.isPicked);
    await _save();
    return _items[index].isPicked ? item.name : null;
  }

  Future<void> removeItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    await _save();
  }

  Future<UpdateItemResult> updateItem(
    String id, {
    required String name,
    required int quantity,
    required GroceryCategory category,
  }) async {
    final cleaned = cleanProductName(name);
    if (cleaned.isEmpty) return UpdateItemResult.empty;

    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return UpdateItemResult.notFound;

    final normalized = normalizeProductName(cleaned);
    final duplicateExists = _items.any(
      (item) => item.id != id && normalizeProductName(item.name) == normalized,
    );
    if (duplicateExists) return UpdateItemResult.duplicate;

    _items[index] = _items[index].copyWith(
      name: cleaned,
      quantity: quantity < 1 ? 1 : quantity,
      category: category,
    );
    await _save();
    return UpdateItemResult.updated;
  }

  Future<void> clearPickedItems() async {
    _items.removeWhere((item) => item.isPicked);
    await _save();
  }

  Future<void> clearAll() async {
    _items.clear();
    await _save();
  }

  Future<void> _save() async {
    await _storage.saveGroceryList(_items);
    notifyListeners();
  }
}
