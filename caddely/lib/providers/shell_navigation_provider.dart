import 'package:flutter/foundation.dart';
import '../models/promo_insight.dart';

class ShellNavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  PromoFilter _promoFilter = PromoFilter.all;
  String? _highlightedProductName;

  int get currentIndex => _currentIndex;
  PromoFilter get promoFilter => _promoFilter;
  String? get highlightedProductName => _highlightedProductName;

  void setTab(int index) {
    if (_currentIndex == index) {
      return;
    }

    _currentIndex = index;
    notifyListeners();
  }

  void goToList() => setTab(0);

  void goToListWithHighlight(String productName) {
    _highlightedProductName = productName;
    _currentIndex = 0;
    notifyListeners();
  }

  void clearHighlight() {
    if (_highlightedProductName == null) return;
    _highlightedProductName = null;
    notifyListeners();
  }

  void goToPromos({PromoFilter filter = PromoFilter.all}) {
    final shouldNotify = _currentIndex != 1 || _promoFilter != filter;
    _currentIndex = 1;
    _promoFilter = filter;
    if (shouldNotify) {
      notifyListeners();
    }
  }

  void goToComparator() => setTab(2);

  void goToHabits() => setTab(3);

  void goToRecipes() => setTab(4);

  void setPromoFilter(PromoFilter filter) {
    if (_promoFilter == filter) {
      return;
    }

    _promoFilter = filter;
    notifyListeners();
  }
}
