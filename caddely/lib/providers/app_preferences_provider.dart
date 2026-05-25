import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class AppPreferencesProvider extends ChangeNotifier {
  final StorageService _storage;

  bool _isLoading = true;
  bool _hasCompletedOnboarding = false;
  bool _hidePickedItems = false;

  AppPreferencesProvider(this._storage);

  bool get isLoading => _isLoading;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get hidePickedItems => _hidePickedItems;

  Future<void> load() async {
    _hasCompletedOnboarding = await _storage.loadHasCompletedOnboarding();
    _hidePickedItems = await _storage.loadHidePickedItems();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await _storage.saveHasCompletedOnboarding(true);
    notifyListeners();
  }

  Future<void> reopenOnboarding() async {
    _hasCompletedOnboarding = false;
    await _storage.saveHasCompletedOnboarding(false);
    notifyListeners();
  }

  Future<void> setHidePickedItems(bool value) async {
    if (_hidePickedItems == value) {
      return;
    }

    _hidePickedItems = value;
    await _storage.saveHidePickedItems(value);
    notifyListeners();
  }
}
