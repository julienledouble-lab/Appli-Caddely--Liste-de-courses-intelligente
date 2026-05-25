import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/promo_insight.dart';
import '../theme/app_theme.dart';

class PromoCard extends StatelessWidget {
  final PromoInsight insight;
  final VoidCallback onPrimaryAction;
  final VoidCallback onCompareBasket;

  const PromoCard({
    super.key,
    required this.insight,
    required this.onPrimaryAction,
    required this.onCompareBasket,
  });

  @override
  Widget build(BuildContext context) {
    final promo = insight.promo;
    final discountPct = promo.discountPercent;
    final deadline = DateFormat('dd MMM').format(promo.validUntil);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.colorBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.colorPromo.withAlpha(26),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                discountPct != null
                    ? '-${discountPct.round()}%'
                    : (promo.discountLabel ?? 'Promo'),
                style: const TextStyle(
                  color: AppTheme.colorPromo,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        promo.productName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.colorTextPrimary,
                        ),
                      ),
                    ),
                    if (insight.quantityInList != null)
                      Text(
                        'x${insight.quantityInList}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.colorTextSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: Icons.store_outlined,
                      label: promo.storeName,
                    ),
                    _InfoPill(
                      icon: Icons.schedule_outlined,
                      label: 'Jusqu\'au $deadline',
                    ),
                    _InfoPill(
                      icon: Icons.person_search_outlined,
                      label: insight.reasonLabel,
                      highlighted: true,
                    ),
                    if (insight.storePriority == PromoStorePriority.primary)
                      const _InfoPill(
                        icon: Icons.star_outline,
                        label: 'Ton magasin',
                        highlighted: true,
                      )
                    else if (insight.storePriority == PromoStorePriority.secondary)
                      const _InfoPill(
                        icon: Icons.compare_arrows_outlined,
                        label: 'Magasin comparé',
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _PriceBlock(insight: insight),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: onPrimaryAction,
                      child: Text(
                        insight.isInCurrentList
                            ? 'Voir dans ma liste'
                            : 'Ajouter à ma liste',
                      ),
                    ),
                    TextButton(
                      onPressed: onCompareBasket,
                      child: const Text('Comparer mon panier'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  final PromoInsight insight;

  const _PriceBlock({required this.insight});

  @override
  Widget build(BuildContext context) {
    final promo = insight.promo;

    if (promo.promoPrice == null || promo.originalPrice == null) {
      return Text(
        promo.discountLabel ?? '',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.colorPromo,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${promo.promoPrice!.toStringAsFixed(2)} €',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.colorCheapest,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${promo.originalPrice!.toStringAsFixed(2)} €',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.colorTextSecondary,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            Text(
              'Économie/unité : ${insight.unitSavings!.toStringAsFixed(2)} €',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.colorPromo,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (insight.estimatedSavings != null)
              Text(
                'Économie estimée : ${insight.estimatedSavings!.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.colorCheapest,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;

  const _InfoPill({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = highlighted
        ? Theme.of(context).colorScheme.primary.withAlpha(20)
        : const Color(0xFFF8FAFC);
    final foreground = highlighted
        ? Theme.of(context).colorScheme.primary
        : AppTheme.colorTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
