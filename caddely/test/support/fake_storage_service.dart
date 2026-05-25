import 'package:caddely/models/grocery_item.dart';
import 'package:caddely/models/purchase_record.dart';
import 'package:caddely/models/recipe.dart';
import 'package:caddely/models/store.dart';
import 'package:caddely/services/storage_service.dart';

class FakeStorageService extends StorageService {
  List<GroceryItem> groceryItems = [];
  List<PurchaseRecord> history = [];
  List<Recipe> recipes = [];
  List<Store> stores = [];
  bool hasCompletedOnboarding = false;
  bool hidePickedItems = false;

  @override
  Future<List<GroceryItem>> loadGroceryList() async => groceryItems;

  @override
  Future<void> saveGroceryList(List<GroceryItem> items) async {
    groceryItems = List<GroceryItem>.from(items);
  }

  @override
  Future<List<PurchaseRecord>> loadHistory() async => history;

  @override
  Future<void> saveHistory(List<PurchaseRecord> records) async {
    history = List<PurchaseRecord>.from(records);
  }

  @override
  Future<List<Recipe>> loadRecipes() async => recipes;

  @override
  Future<void> saveRecipes(List<Recipe> recipes) async {
    this.recipes = List<Recipe>.from(recipes);
  }

  @override
  Future<List<Store>> loadStorePreferences() async => stores;

  @override
  Future<void> saveStorePreferences(List<Store> stores) async {
    this.stores = List<Store>.from(stores);
  }

  @override
  Future<bool> loadHasCompletedOnboarding() async => hasCompletedOnboarding;

  @override
  Future<void> saveHasCompletedOnboarding(bool value) async {
    hasCompletedOnboarding = value;
  }

  @override
  Future<bool> loadHidePickedItems() async => hidePickedItems;

  @override
  Future<void> saveHidePickedItems(bool value) async {
    hidePickedItems = value;
  }
}
