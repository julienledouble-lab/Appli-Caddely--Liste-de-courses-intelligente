import 'package:caddely/providers/store_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_storage_service.dart';

void main() {
  test('only one primary store is possible', () async {
    final provider = StorePreferencesProvider(FakeStorageService());
    await provider.load();

    await provider.setPrimaryStore('carrefour');
    await provider.setPrimaryStore('leclerc');

    expect(provider.primaryStore?.id, 'leclerc');
    expect(provider.stores.where((store) => store.isPrimary), hasLength(1));
  });

  test('a primary store cannot remain secondary', () async {
    final provider = StorePreferencesProvider(FakeStorageService());
    await provider.load();

    await provider.toggleSecondaryStore('carrefour', true);
    await provider.setPrimaryStore('carrefour');

    final carrefour = provider.stores.firstWhere((store) => store.id == 'carrefour');
    expect(carrefour.isPrimary, isTrue);
    expect(carrefour.isSelectedForComparison, isFalse);
  });

  test('applySelection saves primary and secondary stores', () async {
    final storage = FakeStorageService();
    final provider = StorePreferencesProvider(storage);
    await provider.load();

    await provider.applySelection(
      primaryStoreId: 'carrefour',
      secondaryStoreIds: {'leclerc', 'intermarche'},
    );

    expect(provider.primaryStore?.id, 'carrefour');
    expect(
      provider.secondaryStores.map((store) => store.id).toSet(),
      {'leclerc', 'intermarche'},
    );
    expect(storage.stores.where((store) => store.isPrimary).single.id, 'carrefour');
  });
}
