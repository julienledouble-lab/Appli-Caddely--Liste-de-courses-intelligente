import 'package:flutter/foundation.dart';
import '../data/mock_stores.dart';
import '../models/store.dart';
import '../services/storage_service.dart';

class StorePreferencesProvider extends ChangeNotifier {
  final StorageService _storage;

  List<Store> _stores = const [];
  bool _isLoading = true;

  StorePreferencesProvider(this._storage);

  bool get isLoading => _isLoading;
  List<Store> get stores => List.unmodifiable(_stores);
  Store? get primaryStore => _stores.where((store) => store.isPrimary).firstOrNull;
  List<Store> get secondaryStores =>
      _stores.where((store) => store.isSelectedForComparison).toList();

  List<Store> get storesForComparison {
    final selected = <Store?>[
      primaryStore,
      ...secondaryStores,
    ].nonNulls.toList();

    if (selected.isNotEmpty) {
      return selected;
    }

    return stores;
  }

  Future<void> load() async {
    final saved = await _storage.loadStorePreferences();
    if (saved.isEmpty) {
      _stores = mockStores;
    } else {
      _stores = _mergeWithMockStores(saved);
    }
    _isLoading = false;
    await _storage.saveStorePreferences(_stores);
    notifyListeners();
  }

  Future<void> setPrimaryStore(String storeId) async {
    _stores = _stores
        .map(
          (store) => store.copyWith(
            isPrimary: store.id == storeId,
            isSelectedForComparison:
                store.id == storeId ? false : store.isSelectedForComparison,
          ),
        )
        .toList();
    await _save();
  }

  Future<void> applySelection({
    String? primaryStoreId,
    Set<String> secondaryStoreIds = const <String>{},
  }) async {
    _stores = _stores
        .map(
          (store) => store.copyWith(
            isPrimary: primaryStoreId != null && store.id == primaryStoreId,
            isSelectedForComparison: store.id == primaryStoreId
                ? false
                : secondaryStoreIds.contains(store.id),
          ),
        )
        .toList();
    await _save();
  }

  Future<void> clearPrimaryStore() async {
    _stores = _stores.map((store) => store.copyWith(isPrimary: false)).toList();
    await _save();
  }

  Future<void> toggleSecondaryStore(String storeId, bool selected) async {
    _stores = _stores
        .map(
          (store) => store.id == storeId
              ? store.copyWith(
                  isSelectedForComparison: store.isPrimary ? false : selected,
                )
              : store,
        )
        .toList();
    await _save();
  }

  List<Store> _mergeWithMockStores(List<Store> saved) {
    return mockStores.map((mockStore) {
      final existing = saved.where((store) => store.id == mockStore.id).firstOrNull;
      if (existing == null) {
        return mockStore;
      }

      return mockStore.copyWith(
        isPrimary: existing.isPrimary,
        isSelectedForComparison: existing.isPrimary
            ? false
            : existing.isSelectedForComparison,
      );
    }).toList();
  }

  Future<void> _save() async {
    await _storage.saveStorePreferences(_stores);
    notifyListeners();
  }
}
