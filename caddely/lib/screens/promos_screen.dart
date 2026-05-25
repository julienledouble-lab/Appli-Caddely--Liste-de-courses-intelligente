import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_promos.dart';
import '../models/grocery_category.dart';
import '../models/promo_insight.dart';
import '../providers/grocery_provider.dart';
import '../providers/history_provider.dart';
import '../providers/shell_navigation_provider.dart';
import '../providers/store_preferences_provider.dart';
import '../theme/app_theme.dart';
import '../utils/product_name_utils.dart';
import '../utils/promo_utils.dart';
import '../widgets/promo_card.dart';
import '../widgets/section_header.dart';

class PromosScreen extends StatelessWidget {
  const PromosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final grocery = context.watch<GroceryProvider>();
    final history = context.watch<HistoryProvider>();
    final stores = context.watch<StorePreferencesProvider>();
    final navigation = context.watch<ShellNavigationProvider>();

    final insights = buildPromoInsights(
      promotions: mockPromos,
      currentList: grocery.allItems,
      habitualProducts: history.habitProductNames,
      primaryStoreId: stores.primaryStore?.id,
      secondaryStoreIds: stores.secondaryStores.map((store) => store.id).toSet(),
      filter: navigation.promoFilter,
    );
    final summary = buildPromoSummary(
      insights,
      hasPrimaryStore: stores.primaryStore != null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promos utiles'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: const Text('Données fictives'),
              labelStyle: const TextStyle(fontSize: 11),
              backgroundColor: AppTheme.colorPromo.withAlpha(26),
              side: BorderSide(color: AppTheme.colorPromo.withAlpha(77)),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _PromosOverview(
            summaryLabel: summary.summaryLabel(
              hasPrimaryStore: stores.primaryStore != null,
            ),
            currentFilter: navigation.promoFilter,
            onFilterChanged: navigation.setPromoFilter,
          ),
          if (insights.isEmpty)
            const _EmptyPromos()
          else ...[
            const SectionHeader(title: 'PROMOS VRAIMENT UTILES'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (int i = 0; i < insights.length; i++) ...[
                    PromoCard(
                      insight: insights[i],
                      onPrimaryAction: () => _handlePrimaryAction(
                        context,
                        insight: insights[i],
                      ),
                      onCompareBasket: () {
                        context.read<ShellNavigationProvider>().goToComparator();
                      },
                    ),
                    if (i < insights.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
          const _MockDisclaimer(),
        ],
      ),
    );
  }

  Future<void> _handlePrimaryAction(
    BuildContext context, {
    required PromoInsight insight,
  }) async {
    if (insight.isInCurrentList) {
      context
          .read<ShellNavigationProvider>()
          .goToListWithHighlight(insight.promo.productName);
      return;
    }

    final grocery = context.read<GroceryProvider>();
    final history = context.read<HistoryProvider>();
    final matchingRecord = history.records.where((record) {
      return productMatches(record.productName, insight.promo.productName);
    }).firstOrNull;

    final result = await grocery.addItem(
      insight.promo.productName,
      quantity: matchingRecord?.preferredQuantity ?? 1,
      category: matchingRecord?.preferredCategory ?? GroceryCategory.other,
    );

    if (!context.mounted) {
      return;
    }

    final message = switch (result) {
      AddItemResult.added => '${insight.promo.productName} ajouté à la liste.',
      AddItemResult.duplicate =>
        '${insight.promo.productName} est déjà dans la liste.',
      AddItemResult.empty => '',
    };

    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    context.read<ShellNavigationProvider>().goToList();
  }
}

class _PromosOverview extends StatelessWidget {
  final String summaryLabel;
  final PromoFilter currentFilter;
  final ValueChanged<PromoFilter> onFilterChanged;

  const _PromosOverview({
    required this.summaryLabel,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
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
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.colorPromo.withAlpha(22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_offer_outlined,
                    color: AppTheme.colorPromo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    summaryLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.colorTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Tous'),
                  selected: currentFilter == PromoFilter.all,
                  onSelected: (_) => onFilterChanged(PromoFilter.all),
                ),
                ChoiceChip(
                  label: const Text('Mon magasin'),
                  selected: currentFilter == PromoFilter.myStore,
                  onSelected: (_) => onFilterChanged(PromoFilter.myStore),
                ),
                ChoiceChip(
                  label: const Text('Magasins comparés'),
                  selected: currentFilter == PromoFilter.comparedStores,
                  onSelected: (_) => onFilterChanged(PromoFilter.comparedStores),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPromos extends StatelessWidget {
  const _EmptyPromos();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
      child: Column(
        children: [
          Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucune promo utile pour l’instant',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Continue à utiliser ta liste : Caddely repérera les offres liées à tes vrais achats.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
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
                'Ces offres sont basées sur des données d\'exemple. Les tarifs réels peuvent varier selon ton magasin.',
                style: TextStyle(fontSize: 12, color: Colors.amber[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
