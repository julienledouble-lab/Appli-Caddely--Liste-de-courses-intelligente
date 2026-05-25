import 'package:flutter/material.dart';
import '../models/grocery_category.dart';
import '../models/grocery_item.dart';
import '../theme/app_theme.dart';
import '../utils/product_icon_utils.dart';

class GroceryItemTile extends StatelessWidget {
  final GroceryItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool isHighlighted;

  const GroceryItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final productIcon = productIconFor(
      productName: item.name,
      category: item.category,
    );

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: _deleteBackground(),
      onDismissed: (_) => onDelete(),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: item.isPicked ? 0.72 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: item.isPicked
                ? AppTheme.colorPickedBg
                : isHighlighted
                    ? const Color(0xFFEEFBF3)
                    : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighlighted
                  ? AppTheme.colorCheapest
                  : item.isPicked
                      ? AppTheme.colorBorder
                      : const Color(0xFFE2E8F0),
              width: isHighlighted ? 2 : 1,
            ),
            boxShadow: item.isPicked
                ? null
                : [
                    if (isHighlighted)
                      BoxShadow(
                        color: AppTheme.colorCheapest.withAlpha(38),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    else
                      const BoxShadow(
                        color: Color(0x0A0F172A),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                  ],
          ),
          child: InkWell(
            onTap: onToggle,
            onLongPress: onEdit,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  _Checkbox(isPicked: item.isPicked),
                  const SizedBox(width: 12),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: item.isPicked
                          ? const Color(0xFFF1F5F9)
                          : Theme.of(context).colorScheme.primary.withAlpha(14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      productIcon,
                      size: 18,
                      color: item.isPicked
                          ? AppTheme.colorTextSecondary
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: item.isPicked
                                ? AppTheme.colorPicked
                                : AppTheme.colorTextPrimary,
                            decoration: item.isPicked
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppTheme.colorPicked,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Pill(
                              label: 'Qt\u00E9 ${item.quantity}',
                              subtle: item.isPicked,
                            ),
                            _Pill(
                              label: item.category.label,
                              subtle: item.isPicked,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.isPicked
                              ? 'D\u00E9j\u00E0 pris \u00B7 Touche pour le remettre \u00E0 acheter'
                              : 'Touche pour le marquer comme pris',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.colorTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Modifier',
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppTheme.colorTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _deleteBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.colorDiscount,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool subtle;

  const _Pill({required this.label, required this.subtle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: subtle
            ? const Color(0xFFF1F5F9)
            : Theme.of(context).colorScheme.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: subtle
              ? AppTheme.colorTextSecondary
              : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool isPicked;

  const _Checkbox({required this.isPicked});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPicked ? AppTheme.colorPicked : Colors.transparent,
        border: Border.all(
          color: isPicked ? AppTheme.colorPicked : const Color(0xFFCBD5E1),
          width: 2,
        ),
      ),
      child: isPicked
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}
