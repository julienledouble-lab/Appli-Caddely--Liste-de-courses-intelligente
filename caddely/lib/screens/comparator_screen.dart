import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_promos.dart';
import '../models/promo_insight.dart';
import '../data/mock_store_prices.dart';
import '../models/store.dart';
import '../models/store_basket.dart';
import '../models/store_comparison_result.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/grocery_provider.dart';
import '../providers/history_provider.dart';
import '../providers/shell_navigation_provider.dart';
import '../providers/store_preferences_provider.dart';
import 'onboarding_screen.dart';
import '../theme/app_theme.dart';
import '../utils/promo_utils.dart';
import '../utils/store_comparison_utils.dart';
import '../widgets/section_header.dart';

class ComparatorScreen extends StatelessWidget {
  const ComparatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final grocery = context.watch<GroceryProvider>();
    final history = context.watch<HistoryProvider>();
    final appPreferences = context.watch<AppPreferencesProvider>();
    final stores = context.watch<StorePreferencesProvider>();
    final items = grocery.pendingItems;

    if (items.isEmpty) {
      return Scaffold(
        appBar: const _ComparatorAppBar(),
        body: _EmptyComparator(
          appPreferences: appPreferences,
          storesProvider: stores,
        ),
      );
    }

    final totalUnits = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final allBaskets = getStoreBasketsForItems(items);
    final comparison = buildStoreComparisonResult(
      allBaskets: allBaskets,
      selectedStores: stores.storesForComparison,
      primaryStore: stores.primaryStore,
    );
    final comparedStorePromoInsights = buildPromoInsights(
      promotions: mockPromos,
      currentList: grocery.allItems,
      habitualProducts: history.habitProductNames,
      primaryStoreId: stores.primaryStore?.id,
      secondaryStoreIds: stores.secondaryStores.map((store) => store.id).toSet(),
      filter: PromoFilter.comparedStores,
    );

    return Scaffold(
      appBar: _ComparatorAppBar(
        onManageStores: () => _showStoresSheet(context, stores),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _StorePreferencesCard(
            appPreferences: appPreferences,
            storesProvider: stores,
            onManageStores: () => _showStoresSheet(context, stores),
          ),
          _ComparisonSummary(
            itemCount: items.length,
            totalUnits: totalUnits,
            comparison: comparison,
            primaryStore: stores.primaryStore,
          ),
          if (comparedStorePromoInsights.isNotEmpty)
            _PromoComparatorShortcut(
              onOpenPromos: () {
                context.read<ShellNavigationProvider>().goToPromos(
                      filter: PromoFilter.comparedStores,
                    );
              },
            ),
          const SectionHeader(title: 'COMPARAISON PAR MAGASIN'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (int i = 0; i < comparison.baskets.length; i++) ...[
                  _StoreBasketCard(
                    basket: comparison.baskets[i],
                    isCheapest:
                        comparison.baskets[i].storeId == comparison.cheapest.storeId,
                    isPrimary:
                        comparison.primaryBasket?.storeId == comparison.baskets[i].storeId,
                    primaryTotal: comparison.primaryBasket?.totalPrice,
                    rank: i + 1,
                  ),
                  if (i < comparison.baskets.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const _MockDisclaimer(),
        ],
      ),
    );
  }

  Future<void> _showStoresSheet(
    BuildContext context,
    StorePreferencesProvider stores,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mes magasins',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.colorTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choisis ton magasin habituel puis les magasins secondaires \u00E0 comparer.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.colorTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Magasin principal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.colorTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioGroup<String>(
                    groupValue: stores.primaryStore?.id,
                    onChanged: (value) {
                      if (value != null) {
                        stores.setPrimaryStore(value);
                      }
                    },
                    child: Column(
                      children: stores.stores
                          .map(
                            (store) => RadioListTile<String>(
                              value: store.id,
                              contentPadding: EdgeInsets.zero,
                              title: Text(store.name),
                              subtitle: store.isPrimary
                                  ? const Text('Magasin habituel')
                                  : null,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: stores.primaryStore == null
                          ? null
                          : stores.clearPrimaryStore,
                      child: const Text('Retirer le magasin principal'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Magasins secondaires',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.colorTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...stores.stores.map(
                    (store) => CheckboxListTile(
                      value: store.isSelectedForComparison,
                      contentPadding: EdgeInsets.zero,
                      title: Text(store.name),
                      subtitle: store.isPrimary
                          ? const Text('D\u00E9j\u00E0 choisi comme magasin principal')
                          : null,
                      onChanged: store.isPrimary
                          ? null
                          : (value) => stores.toggleSecondaryStore(
                                store.id,
                                value ?? false,
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ComparatorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onManageStores;

  const _ComparatorAppBar({this.onManageStores});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Comparateur'),
      actions: [
        IconButton(
          onPressed: onManageStores,
          icon: const Icon(Icons.storefront_outlined),
          tooltip: 'Mes magasins',
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Chip(
              label: const Text('Donn\u00E9es fictives'),
            labelStyle: const TextStyle(fontSize: 11),
            backgroundColor: AppTheme.colorPromo.withAlpha(26),
            side: BorderSide(color: AppTheme.colorPromo.withAlpha(77)),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _StorePreferencesCard extends StatelessWidget {
  final AppPreferencesProvider appPreferences;
  final StorePreferencesProvider storesProvider;
  final VoidCallback onManageStores;

  const _StorePreferencesCard({
    required this.appPreferences,
    required this.storesProvider,
    required this.onManageStores,
  });

  @override
  Widget build(BuildContext context) {
    final primary = storesProvider.primaryStore;
    final secondaries = storesProvider.secondaryStores;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.colorBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Mes magasins',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.colorTextPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onManageStores,
                  child: const Text('Modifier'),
                ),
              ],
            ),
            Text(
              primary == null
                  ? 'Aucun magasin principal choisi pour le moment.'
                  : 'Magasin habituel : ${primary.name}',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.colorTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            if (secondaries.isEmpty)
              const Text(
                'Aucun magasin secondaire s\u00E9lectionn\u00E9.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.colorTextSecondary,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: secondaries
                    .map(
                      (store) => Chip(
                        label: Text(store.name),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OnboardingScreen(storesOnly: true),
                    ),
                  );
                },
                child: const Text('Revoir la configuration'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonSummary extends StatelessWidget {
  final int itemCount;
  final int totalUnits;
  final StoreComparisonResult comparison;
  final Store? primaryStore;

  const _ComparisonSummary({
    required this.itemCount,
    required this.totalUnits,
    required this.comparison,
    required this.primaryStore,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = comparison.isPrimaryBestChoice
        ? AppTheme.colorCheapest
        : comparison.isUsefulSavings
            ? AppTheme.colorPromo
            : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withAlpha(28),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withAlpha(51)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              primaryStore == null
                  ? 'Comparaison sans magasin principal'
                  : 'R\u00E9f\u00E9rence : ${primaryStore!.name}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.colorTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  comparison.cheapest.storeEmoji,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${comparison.cheapest.storeName} est le moins cher pour $itemCount produit${itemCount > 1 ? 's' : ''} et $totalUnits unit\u00E9${totalUnits > 1 ? 's' : ''}.',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.colorTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${comparison.cheapest.totalPrice.toStringAsFixed(2)} \u20AC au total',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              comparison.message,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.colorTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreBasketCard extends StatelessWidget {
  final StoreBasket basket;
  final bool isCheapest;
  final bool isPrimary;
  final double? primaryTotal;
  final int rank;

  const _StoreBasketCard({
    required this.basket,
    required this.isCheapest,
    required this.isPrimary,
    required this.primaryTotal,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final deltaVsPrimary = primaryTotal == null
        ? null
        : basket.totalPrice - primaryTotal!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCheapest
              ? AppTheme.colorCheapest.withAlpha(102)
              : isPrimary
                  ? Theme.of(context).colorScheme.primary.withAlpha(102)
                  : AppTheme.colorBorder,
          width: isCheapest || isPrimary ? 2 : 1,
        ),
      ),
      child: ExpansionTile(
        shape: const Border(),
        tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: _RankBadge(
          rank: rank,
          isCheapest: isCheapest,
          isPrimary: isPrimary,
        ),
        title: Row(
          children: [
            Text(basket.storeEmoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    basket.storeName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isCheapest
                          ? AppTheme.colorCheapest
                          : AppTheme.colorTextPrimary,
                    ),
                  ),
                  if (isPrimary)
                    Text(
                      'Magasin habituel',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else if (isCheapest)
                    const Text(
                      'Le moins cher',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.colorCheapest,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else if (deltaVsPrimary != null)
                    Text(
                      deltaVsPrimary >= 0
                          ? '+${deltaVsPrimary.toStringAsFixed(2)} \u20AC vs habituel'
                          : '${deltaVsPrimary.toStringAsFixed(2)} \u20AC vs habituel',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.colorTextSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        trailing: Text(
          '${basket.totalPrice.toStringAsFixed(2)} \u20AC',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isCheapest
                ? AppTheme.colorCheapest
                : AppTheme.colorTextPrimary,
          ),
        ),
        children: basket.itemPrices
            .map(
              (itemPrice) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemPrice.productName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.colorTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${itemPrice.quantity} x ${itemPrice.unitPrice.toStringAsFixed(2)} \u20AC',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.colorTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${itemPrice.totalPrice.toStringAsFixed(2)} \u20AC',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.colorTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PromoComparatorShortcut extends StatelessWidget {
  final VoidCallback onOpenPromos;

  const _PromoComparatorShortcut({required this.onOpenPromos});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onOpenPromos,
          icon: const Icon(Icons.local_offer_outlined, size: 18),
          label: const Text('Voir les promos de tes magasins'),
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final bool isCheapest;
  final bool isPrimary;

  const _RankBadge({
    required this.rank,
    required this.isCheapest,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCheapest
        ? AppTheme.colorCheapest
        : isPrimary
            ? Theme.of(context).colorScheme.primary
            : const Color(0xFFE2E8F0);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: isCheapest || isPrimary
                ? Colors.white
                : AppTheme.colorTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _EmptyComparator extends StatelessWidget {
  final AppPreferencesProvider appPreferences;
  final StorePreferencesProvider storesProvider;

  const _EmptyComparator({
    required this.appPreferences,
    required this.storesProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compare_arrows_outlined,
              size: 72,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Rien \u00E0 comparer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              storesProvider.primaryStore == null
                  ? 'Choisis d\'abord ton magasin habituel puis ajoute des produits \u00E0 acheter.'
                  : 'Ajoute des produits \u00E0 acheter pour comparer tes magasins favoris.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const OnboardingScreen(storesOnly: true),
                  ),
                );
              },
              child: const Text('Revoir la configuration'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockDisclaimer extends StatelessWidget {
  const _MockDisclaimer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.amber[700]),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ces prix sont indicatifs et bas\u00E9s sur des donn\u00E9es d\'exemple. Les tarifs r\u00E9els peuvent varier.',
                style: TextStyle(fontSize: 12, color: Colors.amber[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
