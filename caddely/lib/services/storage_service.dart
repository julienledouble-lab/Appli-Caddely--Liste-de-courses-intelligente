import 'package:shared_preferences/shared_preferences.dart';
import '../models/grocery_item.dart';
import '../models/purchase_record.dart';
import '../models/recipe.dart';
import '../models/store.dart';
import '../models/store_preferences_codec.dart';

class StorageService {
  static const _listKey = 'caddely_grocery_list';
  static const _historyKey = 'caddely_purchase_history';
  static const _storesKey = 'caddely_store_preferences';
  static const _onboardingKey = 'caddely_onboarding_completed';
  static const _hidePickedItemsKey = 'caddely_hide_picked_items';
  static const _recipesKey = 'caddely_recipes';

  Future<List<GroceryItem>> loadGroceryList() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_listKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      return GroceryItem.listFromJson(jsonStr);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveGroceryList(List<GroceryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_listKey, GroceryItem.listToJson(items));
  }

  Future<List<PurchaseRecord>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_historyKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      return PurchaseRecord.listFromJson(jsonStr);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHistory(List<PurchaseRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, PurchaseRecord.listToJson(records));
  }

  Future<List<Store>> loadStorePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storesKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      return StorePreferencesCodec.listFromJson(jsonStr);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveStorePreferences(List<Store> stores) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storesKey, StorePreferencesCodec.listToJson(stores));
  }

  Future<bool> loadHasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> saveHasCompletedOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, value);
  }

  Future<bool> loadHidePickedItems() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hidePickedItemsKey) ?? false;
  }

  Future<void> saveHidePickedItems(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hidePickedItemsKey, value);
  }

  Future<List<Recipe>> loadRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_recipesKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    try {
      return Recipe.listFromJson(jsonStr);
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecipes(List<Recipe> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recipesKey, Recipe.listToJson(recipes));
  }
}
