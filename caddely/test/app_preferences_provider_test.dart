import 'package:caddely/providers/app_preferences_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/fake_storage_service.dart';

void main() {
  test('completeOnboarding saves onboarding as completed', () async {
    final storage = FakeStorageService();
    final provider = AppPreferencesProvider(storage);

    await provider.load();
    await provider.completeOnboarding();

    expect(provider.hasCompletedOnboarding, isTrue);
    expect(storage.hasCompletedOnboarding, isTrue);
  });

  test('setHidePickedItems saves picked visibility preference', () async {
    final storage = FakeStorageService();
    final provider = AppPreferencesProvider(storage);

    await provider.load();
    await provider.setHidePickedItems(true);

    expect(provider.hidePickedItems, isTrue);
    expect(storage.hidePickedItems, isTrue);
  });
}
