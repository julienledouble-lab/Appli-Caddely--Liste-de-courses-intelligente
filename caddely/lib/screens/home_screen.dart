import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_promos.dart';
import '../data/quick_start_products.dart';
import '../models/grocery_category.dart';
import '../models/grocery_item.dart';
import '../models/habit_suggestion.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/grocery_provider.dart';
import '../providers/history_provider.dart';
import '../providers/shell_navigation_provider.dart';
import '../providers/store_preferences_provider.dart';
import '../theme/app_theme.dart';
import '../utils/grocery_category_utils.dart';
import '../utils/product_name_utils.dart';
import '../utils/promo_utils.dart';
import '../utils/shopping_trip_utils.dart';
import '../utils/suggestion_engine.dart';
import '../widgets/grocery_item_tile.dart';
import '../widgets/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _addController = TextEditingController();
  final _addFocus = FocusNode();
  final Set<GroceryCategory> _collapsedCategories = <GroceryCategory>{};
  int _draftQuantity = 1;
  GroceryCategory _draftCategory = GroceryCategory.other;
  bool _showQuickOptions = false;

  String? _highlightedItemId;
  Timer? _highlightTimer;
  ShellNavigationProvider? _navProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = context.read<ShellNavigationProvider>();
    if (_navProvider != nav) {
      _navProvider?.removeListener(_handleNavigationHighlight);
      _navProvider = nav;
      _navProvider!.addListener(_handleNavigationHighlight);
    }
  }

  void _handleNavigationHighlight() {
    final highlighted = _navProvider?.highlightedProductName;
    if (highlighted == null) return;

    final grocery = context.read<GroceryProvider>();
    final match = grocery.allItems
        .where(
          (item) =>
              normalizeProductName(item.name) ==
              normalizeProductName(highlighted),
        )
        .firstOrNull;

    setState(() => _highlightedItemId = match?.id);
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _highlightedItemId = null);
        _navProvider?.clearHighlight();
      }
    });
  }

  @override
  void dispose() {
    _navProvider?.removeListener(_handleNavigationHighlight);
    _highlightTimer?.cancel();
    _addController.dispose();
    _addFocus.dispose();
    super.dispose();
  }

  Future<void> _addItem(
    GroceryProvider grocery, {
    String? customName,
    int? quantity,
    GroceryCategory? category,
  }) async {
    final result = await grocery.addItem(
      customName ?? _addController.text,
      quantity: quantity ?? _draftQuantity,
      category: category ?? _draftCategory,
    );

    if (!mounted) {
      return;
    }

    switch (result) {
      case AddItemResult.added:
        _addController.clear();
        setState(() {
          _draftQuantity = 1;
          _draftCategory = GroceryCategory.other;
          _showQuickOptions = false;
        });
        _addFocus.requestFocus();
        break;
      case AddItemResult.duplicate:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ce produit est déjà dans ta liste.'),
          ),
        );
        _addFocus.requestFocus();
        break;
      case AddItemResult.empty:
        break;
    }
  }

  Future<void> _toggleItem(
    GroceryProvider grocery,
    HistoryProvider history,
    GroceryItem item,
  ) async {
    final pickedName = await grocery.toggleItem(item.id);
    if (pickedName != null) {
      await history.recordPurchase(
        pickedName,
        quantity: item.quantity,
        category: item.category,
      );
    }
  }

  Future<void> _showEditDialog(GroceryProvider grocery, GroceryItem item) async {
    final nameController = TextEditingController(text: item.name);
    var quantity = item.quantity;
    var category = item.category;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Modifier le produit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.colorTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Nom du produit',
                      ),
                      onSubmitted: (_) async {
                        await _submitEdit(
                          dialogContext,
                          grocery,
                          item.id,
                          nameController.text,
                          quantity,
                          category,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _AddOptionsRow(
                      quantity: quantity,
                      category: category,
                      onDecrease: quantity > 1
                          ? () => setSheetState(() => quantity--)
                          : null,
                      onIncrease: () => setSheetState(() => quantity++),
                      onCategoryChanged: (value) {
                        setSheetState(() => category = value);
                      },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              await _submitEdit(
                                dialogContext,
                                grocery,
                                item.id,
                                nameController.text,
                                quantity,
                                category,
                              );
                            },
                            child: const Text('Enregistrer'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitEdit(
    BuildContext dialogContext,
    GroceryProvider grocery,
    String itemId,
    String newName,
    int quantity,
    GroceryCategory category,
  ) async {
    final result = await grocery.updateItem(
      itemId,
      name: newName,
      quantity: quantity,
      category: category,
    );

    if (!mounted) {
      return;
    }

    if (result == UpdateItemResult.updated) {
      if (!dialogContext.mounted) {
        return;
      }
      Navigator.of(dialogContext).pop();
      return;
    }

    final message = switch (result) {
      UpdateItemResult.duplicate =>
        'Un produit avec ce nom existe déjà dans la liste.',
      UpdateItemResult.empty => 'Le nom du produit ne peut pas être vide.',
      UpdateItemResult.notFound => 'Produit introuvable.',
      UpdateItemResult.updated => '',
    };

    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _showClearConfirm(GroceryProvider grocery) async {
    final shouldClear = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Vider les produits déjà pris'),
            content: const Text(
              'Supprimer tous les produits cochés de la liste ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.colorDiscount,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldClear) {
      await grocery.clearPickedItems();
    }
  }

  Future<void> _showFinishTripConfirm(GroceryProvider grocery) async {
    final shouldFinish = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Terminer cette liste ?'),
            content: const Text(
              'Les produits pris resteront dans tes habitudes. Ta liste actuelle sera vidée.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.colorDiscount,
                ),
                child: const Text('Terminer'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldFinish) {
      await grocery.clearAll();
    }
  }

  Future<void> _quickAddSuggestion(
    GroceryProvider grocery,
    HabitSuggestion suggestion,
  ) async {
    await _addItem(
      grocery,
      customName: suggestion.productName,
      quantity: suggestion.quantity,
      category: suggestion.category,
    );
  }

  void _toggleCategoryCollapse(GroceryCategory category) {
    setState(() {
      if (_collapsedCategories.contains(category)) {
        _collapsedCategories.remove(category);
      } else {
        _collapsedCategories.add(category);
      }
    });
  }

  void _expandAllCategories(Iterable<GroceryCategory> categories) {
    setState(() {
      _collapsedCategories.removeAll(categories);
    });
  }

  void _collapseAllCategories(Iterable<GroceryCategory> categories) {
    setState(() {
      _collapsedCategories
        ..clear()
        ..addAll(categories);
    });
  }

  @override
  Widget build(BuildContext context) {
    final grocery = context.watch<GroceryProvider>();
    final history = context.watch<HistoryProvider>();
    final appPreferences = context.watch<AppPreferencesProvider>();
    final stores = context.watch<StorePreferencesProvider>();

    if (grocery.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pending = grocery.pendingItems;
    final picked = grocery.pickedItems;
    final allItems = grocery.allItems;
    final total = allItems.length;
    final groupedPending = groupItemsByOrderedCategory(pending);
    final progress = buildShoppingTripProgress(allItems);
    final nextItem = findNextItemToPick(groupedPending);
    final currentNames = allItems
        .map((item) => normalizeProductName(item.name))
        .toSet();
    final suggestions = buildSuggestions(
      sortedHistory: history.sortedByFrequency,
      query: _addController.text,
      excludedNames: currentNames,
    );
    final promoInsights = buildPromoInsights(
      promotions: mockPromos,
      currentList: allItems,
      habitualProducts: history.habitProductNames,
      primaryStoreId: stores.primaryStore?.id,
      secondaryStoreIds: stores.secondaryStores.map((store) => store.id).toSet(),
    );
    final visibleCategories = groupedPending.keys.toList();
    final showPickedItems = !appPreferences.hidePickedItems;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ma liste'),
            if (total > 0)
              Text(
                '$total article${total > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.colorTextSecondary,
                ),
              ),
          ],
        ),
        actions: [
          if (picked.isNotEmpty && showPickedItems)
            IconButton(
              onPressed: () => _showClearConfirm(grocery),
              icon: const Icon(Icons.cleaning_services_outlined),
              tooltip: 'Vider les produits déjà pris',
            ),
        ],
      ),
      body: Column(
        children: [
          _AddItemBar(
            controller: _addController,
            focusNode: _addFocus,
            quantity: _draftQuantity,
            category: _draftCategory,
            showQuickOptions: _showQuickOptions,
            suggestions: suggestions,
            onToggleOptions: () {
              setState(() => _showQuickOptions = !_showQuickOptions);
            },
            onQuantityChanged: (value) {
              setState(() => _draftQuantity = value);
            },
            onCategoryChanged: (value) {
              setState(() => _draftCategory = value);
            },
            onAdd: () => _addItem(grocery),
            onTextChanged: (_) => setState(() {}),
            onQuickAdd: (suggestion) => _quickAddSuggestion(grocery, suggestion),
          ),
          Expanded(
            child: total == 0
                ? _EmptyState(
                    onQuickAdd: (product) => _addItem(
                      grocery,
                      customName: product.name,
                      quantity: product.quantity,
                      category: product.category,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      _ShoppingTripCard(
                        progress: progress,
                        nextItem: nextItem,
                        hasPendingItems: pending.isNotEmpty,
                        hasCollapsedCategories:
                            visibleCategories.any(_collapsedCategories.contains),
                        hasExpandedCategories:
                            visibleCategories.any(
                              (category) =>
                                  !_collapsedCategories.contains(category),
                            ),
                        hidePickedItems: appPreferences.hidePickedItems,
                        onExpandAll: () => _expandAllCategories(visibleCategories),
                        onCollapseAll: () =>
                            _collapseAllCategories(visibleCategories),
                        onTogglePickedVisibility: () {
                          appPreferences.setHidePickedItems(
                            !appPreferences.hidePickedItems,
                          );
                        },
                        onFinishTrip: () => _showFinishTripConfirm(grocery),
                      ),
                      if (promoInsights.isNotEmpty)
                        _PromoShortcutCard(
                          count: promoInsights.length,
                          onOpenPromos: () {
                            context.read<ShellNavigationProvider>().goToPromos();
                          },
                        ),
                      if (pending.isNotEmpty) ...[
                        SectionHeader(title: 'À ACHETER (${pending.length})'),
                        ...groupedPending.entries.map(
                          (entry) => _CategorySection(
                            category: entry.key,
                            items: entry.value,
                            isCollapsed:
                                _collapsedCategories.contains(entry.key),
                            highlightedItemId: _highlightedItemId,
                            onToggleCollapsed: () =>
                                _toggleCategoryCollapse(entry.key),
                            onToggle: (item) =>
                                _toggleItem(grocery, history, item),
                            onDelete: (item) => grocery.removeItem(item.id),
                            onEdit: (item) => _showEditDialog(grocery, item),
                          ),
                        ),
                      ],
                      if (picked.isNotEmpty && !showPickedItems)
                        _PickedSummaryCard(count: picked.length),
                      if (picked.isNotEmpty && showPickedItems) ...[
                        SectionHeader(
                          title: 'DÉJÀ PRIS (${picked.length})',
                          trailing: 'Vider',
                          onTrailingTap: () => _showClearConfirm(grocery),
                        ),
                        ...picked.map(
                          (item) => GroceryItemTile(
                            key: Key(item.id),
                            item: item,
                            isHighlighted: item.id == _highlightedItemId,
                            onToggle: () =>
                                _toggleItem(grocery, history, item),
                            onDelete: () => grocery.removeItem(item.id),
                            onEdit: () => _showEditDialog(grocery, item),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _AddItemBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int quantity;
  final GroceryCategory category;
  final bool showQuickOptions;
  final List<HabitSuggestion> suggestions;
  final VoidCallback onToggleOptions;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<GroceryCategory> onCategoryChanged;
  final VoidCallback onAdd;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<HabitSuggestion> onQuickAdd;

  const _AddItemBar({
    required this.controller,
    required this.focusNode,
    required this.quantity,
    required this.category,
    required this.showQuickOptions,
    required this.suggestions,
    required this.onToggleOptions,
    required this.onQuantityChanged,
    required this.onCategoryChanged,
    required this.onAdd,
    required this.onTextChanged,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Ajouter un produit',
                    prefixIcon: const Icon(Icons.add, size: 20),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (controller.text.isNotEmpty)
                          IconButton(
                            onPressed: () {
                              controller.clear();
                              onTextChanged('');
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        IconButton(
                          onPressed: onToggleOptions,
                          icon: Icon(
                            showQuickOptions
                                ? Icons.tune
                                : Icons.tune_outlined,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onChanged: onTextChanged,
                  onSubmitted: (_) => onAdd(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Ajouter'),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: showQuickOptions
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _AddOptionsRow(
                      quantity: quantity,
                      category: category,
                      onDecrease: quantity > 1
                          ? () => onQuantityChanged(quantity - 1)
                          : null,
                      onIncrease: () => onQuantityChanged(quantity + 1),
                      onCategoryChanged: onCategoryChanged,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: suggestions.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: suggestions
                          .map(
                            (suggestion) => _SuggestionTile(
                              key: Key('suggestion-${suggestion.productName}'),
                              suggestion: suggestion,
                              onTap: () => onQuickAdd(suggestion),
                            ),
                          )
                          .toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final HabitSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionTile({
    super.key,
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFromHistory = suggestion.frequency > 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  isFromHistory ? Icons.history : Icons.search,
                  size: 18,
                  color: AppTheme.colorTextSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.productName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'x${suggestion.quantity} · ${suggestion.category.label}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.colorTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.add_circle_outline, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddOptionsRow extends StatelessWidget {
  final int quantity;
  final GroceryCategory category;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;
  final ValueChanged<GroceryCategory> onCategoryChanged;

  const _AddOptionsRow({
    required this.quantity,
    required this.category,
    required this.onDecrease,
    required this.onIncrease,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.colorBorder),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onDecrease,
                icon: const Icon(Icons.remove, size: 18),
                visualDensity: VisualDensity.compact,
              ),
              Text(
                '$quantity',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: onIncrease,
                icon: const Icon(Icons.add, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<GroceryCategory>(
            initialValue: category,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: GroceryCategory.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onCategoryChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _ShoppingTripCard extends StatelessWidget {
  final ShoppingTripProgress progress;
  final GroceryItem? nextItem;
  final bool hasPendingItems;
  final bool hasCollapsedCategories;
  final bool hasExpandedCategories;
  final bool hidePickedItems;
  final VoidCallback onExpandAll;
  final VoidCallback onCollapseAll;
  final VoidCallback onTogglePickedVisibility;
  final VoidCallback onFinishTrip;

  const _ShoppingTripCard({
    required this.progress,
    required this.nextItem,
    required this.hasPendingItems,
    required this.hasCollapsedCategories,
    required this.hasExpandedCategories,
    required this.hidePickedItems,
    required this.onExpandAll,
    required this.onCollapseAll,
    required this.onTogglePickedVisibility,
    required this.onFinishTrip,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withAlpha(24),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: primaryColor.withAlpha(38)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.summaryLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.colorTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progress.totalCount == 0
                            ? 'Ajoute quelques produits pour démarrer tes courses.'
                            : '${progress.completionPercent}% de la liste est déjà validé.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.colorTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _OverviewMetric(
                  label: 'Restants',
                  value: '${progress.pendingCount}',
                  color: primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress.completionRatio,
                backgroundColor: const Color(0xFFE2E8F0),
              ),
            ),
            const SizedBox(height: 14),
            _NextItemCard(nextItem: nextItem, hasPendingItems: hasPendingItems),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  key: const Key('expand-all-categories'),
                  label: const Text('Tout déplier'),
                  onPressed: hasCollapsedCategories ? onExpandAll : null,
                ),
                ActionChip(
                  key: const Key('collapse-all-categories'),
                  label: const Text('Tout replier'),
                  onPressed: hasExpandedCategories ? onCollapseAll : null,
                ),
                ActionChip(
                  key: const Key('toggle-picked-visibility'),
                  label: Text(
                    hidePickedItems
                        ? 'Afficher les produits pris'
                        : 'Masquer les produits pris',
                  ),
                  onPressed: onTogglePickedVisibility,
                ),
                ActionChip(
                  key: const Key('finish-trip'),
                  avatar: const Icon(Icons.flag_outlined, size: 16),
                  label: const Text('Terminer mes courses'),
                  onPressed: onFinishTrip,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NextItemCard extends StatelessWidget {
  final GroceryItem? nextItem;
  final bool hasPendingItems;

  const _NextItemCard({
    required this.nextItem,
    required this.hasPendingItems,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.colorBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasPendingItems ? Icons.flag_outlined : Icons.check_circle_outline,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prochain à prendre',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.colorTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nextItem == null
                      ? 'Tout est pris, tu peux finaliser tranquillement.'
                      : '${nextItem!.name} x${nextItem!.quantity}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.colorTextPrimary,
                  ),
                ),
                if (nextItem != null)
                  Text(
                    nextItem!.category.label,
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
    );
  }
}

class _CategorySection extends StatelessWidget {
  final GroceryCategory category;
  final List<GroceryItem> items;
  final bool isCollapsed;
  final String? highlightedItemId;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<GroceryItem> onToggle;
  final ValueChanged<GroceryItem> onDelete;
  final ValueChanged<GroceryItem> onEdit;

  const _CategorySection({
    required this.category,
    required this.items,
    required this.isCollapsed,
    this.highlightedItemId,
    required this.onToggleCollapsed,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('toggle-category-${category.storageKey}'),
              onTap: onToggleCollapsed,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.colorTextPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${items.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.colorTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isCollapsed
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      size: 18,
                      color: AppTheme.colorTextSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: isCollapsed
              ? const SizedBox.shrink()
              : Column(
                  children: items
                      .map(
                        (item) => GroceryItemTile(
                          key: Key(item.id),
                          item: item,
                          isHighlighted: item.id == highlightedItemId,
                          onToggle: () => onToggle(item),
                          onDelete: () => onDelete(item),
                          onEdit: () => onEdit(item),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _PickedSummaryCard extends StatelessWidget {
  final int count;

  const _PickedSummaryCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.colorPickedBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.colorBorder),
        ),
        child: Text(
          '$count produit${count > 1 ? 's' : ''} déjà pris',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.colorTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _PromoShortcutCard extends StatelessWidget {
  final int count;
  final VoidCallback onOpenPromos;

  const _PromoShortcutCard({
    required this.count,
    required this.onOpenPromos,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.colorBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_offer_outlined,
              size: 18,
              color: AppTheme.colorPromo,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count promo${count > 1 ? 's' : ''} utile${count > 1 ? 's' : ''} pour ta liste',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colorTextPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: onOpenPromos,
              child: const Text('Voir les promos'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ValueChanged<QuickStartProduct> onQuickAdd;

  const _EmptyState({required this.onQuickAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: 72,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Ta liste est vide',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoute tes premiers produits',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              'Plus tu utilises Caddely, plus l\'app repère tes habitudes et t\'aide à comparer les bons prix.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: quickStartProducts
                  .map(
                    (product) => ActionChip(
                      label: Text(product.name),
                      onPressed: () => onQuickAdd(product),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
