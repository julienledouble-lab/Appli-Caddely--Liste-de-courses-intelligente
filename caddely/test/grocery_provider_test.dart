import 'package:caddely/models/grocery_category.dart';
import 'package:caddely/providers/grocery_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_storage_service.dart';

void main() {
  test('addItem prevents duplicates from suggestion style quick add', () async {
    final provider = GroceryProvider(FakeStorageService());

    final first = await provider.addItem(
      'Lait',
      quantity: 2,
      category: GroceryCategory.fresh,
    );
    final second = await provider.addItem(
      ' lait ',
      quantity: 2,
      category: GroceryCategory.fresh,
    );

    expect(first, AddItemResult.added);
    expect(second, AddItemResult.duplicate);
    expect(provider.allItems, hasLength(1));
  });
}
