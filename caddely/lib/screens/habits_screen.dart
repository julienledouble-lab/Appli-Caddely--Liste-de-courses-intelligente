import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/grocery_category.dart';
import '../models/purchase_record.dart';
import '../providers/grocery_provider.dart';
import '../providers/history_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/section_header.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final grocery = context.watch<GroceryProvider>();
    final sorted = history.sortedByFrequency;

    return Scaffold(
      appBar: AppBar(title: const Text('Habitudes')),
      body: sorted.isEmpty
          ? const _EmptyHabits()
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                _HabitOverview(history: history),
                SectionHeader(title: 'PRODUITS LES PLUS FR\u00C9QUENTS'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (int i = 0; i < sorted.length; i++) ...[
                        _HabitTile(
                          record: sorted[i],
                          rank: i + 1,
                          alreadyInList: grocery.containsProductName(
                            sorted[i].productName,
                          ),
                          onAdd: () async {
                            final result = await grocery.addItem(
                              sorted[i].productName,
                              quantity: sorted[i].preferredQuantity,
                              category: sorted[i].preferredCategory,
                            );

                            if (!context.mounted) return;
                            final message = switch (result) {
                              AddItemResult.added =>
                                '${sorted[i].productName} ajout\u00E9 \u00E0 la liste.',
                              AddItemResult.duplicate =>
                                '${sorted[i].productName} est d\u00E9j\u00E0 dans la liste.',
                              AddItemResult.empty => '',
                            };
                            if (message.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            }
                          },
                        ),
                        if (i < sorted.length - 1) const Divider(indent: 56),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _InfoBanner(),
              ],
            ),
    );
  }
}

class _HabitOverview extends StatelessWidget {
  final HistoryProvider history;

  const _HabitOverview({required this.history});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Habituels',
                  value: '${history.habitProducts.length}',
                  icon: Icons.star_rounded,
                  color: AppTheme.colorHabit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'R\u00E9cents',
                  value: '${history.recentProducts.length}',
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFF0EA5E9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.colorBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prochaine base de suggestions',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.colorTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  history.topProducts
                      .take(3)
                      .map((record) => record.productName)
                      .join(' \u2022 '),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.colorTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Les quantit\u00E9s et cat\u00E9gories habituelles servent maintenant \u00E0 enrichir les suggestions locales.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.colorTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.colorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.colorTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  final PurchaseRecord record;
  final int rank;
  final bool alreadyInList;
  final VoidCallback onAdd;

  const _HabitTile({
    required this.record,
    required this.rank,
    required this.alreadyInList,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy', 'fr_FR')
        .format(record.lastPurchasedAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _primaryColor(record).withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _primaryColor(record),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.productName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.colorTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(
                      label: '${record.preferredCategory.label} \u2022 Qt\u00E9 ${record.preferredQuantity}',
                      color: AppTheme.colorTextSecondary,
                      icon: Icons.shopping_basket_outlined,
                    ),
                    if (record.isHabit)
                      const _Badge(
                        label: 'Produit habituel',
                        color: AppTheme.colorHabit,
                        icon: Icons.star_rounded,
                      ),
                    if (record.isRecent)
                      const _Badge(
                        label: 'Achet\u00E9 r\u00E9cemment',
                        color: Color(0xFF0EA5E9),
                        icon: Icons.schedule_rounded,
                      ),
                    if (record.isFrequent)
                      const _Badge(
                        label: 'Fr\u00E9quent',
                        color: AppTheme.colorCheapest,
                        icon: Icons.repeat_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Dernier achat : $dateStr',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.colorTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: alreadyInList ? null : onAdd,
            icon: Icon(alreadyInList ? Icons.check : Icons.add),
            label: Text(alreadyInList ? 'D\u00E9j\u00E0 l\u00E0' : 'Ajouter'),
          ),
        ],
      ),
    );
  }

  Color _primaryColor(PurchaseRecord record) {
    if (record.isHabit) return AppTheme.colorHabit;
    if (record.isRecent) return const Color(0xFF0EA5E9);
    if (record.isFrequent) return AppTheme.colorCheapest;
    return AppTheme.colorTextSecondary;
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _Badge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHabits extends StatelessWidget {
  const _EmptyHabits();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Pas encore d\'habitudes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cochez des produits dans votre liste pour que Caddely d\u00E9tecte vos achats r\u00E9currents.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.colorHabit.withAlpha(13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.colorHabit.withAlpha(51)),
        ),
        child: const Row(
          children: [
            Icon(Icons.auto_awesome, size: 18, color: AppTheme.colorHabit),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cette base locale sert \u00E0 sugg\u00E9rer les produits \u00E0 racheter avec leur quantit\u00E9 et cat\u00E9gorie habituelles.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.colorHabit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
