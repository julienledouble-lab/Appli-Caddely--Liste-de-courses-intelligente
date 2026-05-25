import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_stores.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/store_preferences_provider.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final bool storesOnly;

  const OnboardingScreen({
    super.key,
    this.storesOnly = false,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late int _currentStep = widget.storesOnly ? 1 : 0;
  String? _primaryStoreId;
  final Set<String> _secondaryStoreIds = <String>{};
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_primaryStoreId != null || _secondaryStoreIds.isNotEmpty) {
      return;
    }

    final storesProvider = context.read<StorePreferencesProvider>();
    _primaryStoreId = storesProvider.primaryStore?.id;
    _secondaryStoreIds
      ..clear()
      ..addAll(storesProvider.secondaryStores.map((store) => store.id));
  }

  @override
  Widget build(BuildContext context) {
    final availableSecondaryStores = mockStores
        .where((store) => store.id != _primaryStoreId)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              _OnboardingProgress(
                currentStep: _displayStep,
                totalSteps: widget.storesOnly ? 3 : 4,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: switch (_currentStep) {
                    0 => _WelcomeStep(
                        onStart: _nextStep,
                        onSkip: _skipForNow,
                      ),
                    1 => _PrimaryStoreStep(
                        selectedStoreId: _primaryStoreId,
                        onSelected: (value) {
                          setState(() {
                            _primaryStoreId = value;
                            _secondaryStoreIds.remove(value);
                          });
                        },
                      ),
                    2 => _SecondaryStoresStep(
                        availableStoreIds: availableSecondaryStores
                            .map((store) => store.id)
                            .toSet(),
                        selectedStoreIds: _secondaryStoreIds,
                        onToggle: (storeId, selected) {
                          setState(() {
                            if (selected) {
                              _secondaryStoreIds.add(storeId);
                            } else {
                              _secondaryStoreIds.remove(storeId);
                            }
                          });
                        },
                      ),
                    _ => _ReadyStep(storesOnly: widget.storesOnly),
                  },
                ),
              ),
              if (_showBottomActions)
                _BottomActions(
                  currentStep: _currentStep,
                  isSubmitting: _isSubmitting,
                  canContinue: _canContinue,
                  onBack: _canGoBack ? _previousStep : null,
                  onContinue: _isLastStep ? _completeOnboarding : _nextStep,
                ),
            ],
          ),
        ),
      ),
    );
  }

  int get _displayStep => widget.storesOnly ? _currentStep - 1 : _currentStep;
  bool get _showBottomActions => !widget.storesOnly || _currentStep > 0;
  bool get _canGoBack => widget.storesOnly ? _currentStep > 1 : _currentStep > 0;
  bool get _isLastStep => _currentStep == 3;

  bool get _canContinue => switch (_currentStep) {
        1 => _primaryStoreId != null,
        _ => true,
      };

  void _nextStep() {
    if (!_canContinue) {
      return;
    }

    setState(() {
      _currentStep = (_currentStep + 1).clamp(widget.storesOnly ? 1 : 0, 3);
    });
  }

  void _previousStep() {
    setState(() {
      _currentStep = (_currentStep - 1).clamp(widget.storesOnly ? 1 : 0, 3);
    });
  }

  Future<void> _skipForNow() async {
    await context.read<AppPreferencesProvider>().completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    final storesProvider = context.read<StorePreferencesProvider>();
    final appPreferences = context.read<AppPreferencesProvider>();

    await storesProvider.applySelection(
      primaryStoreId: _primaryStoreId,
      secondaryStoreIds: _secondaryStoreIds,
    );

    if (widget.storesOnly) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      await appPreferences.completeOnboarding();
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}

class _OnboardingProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _OnboardingProgress({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(
            totalSteps,
            (index) => Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 8),
                decoration: BoxDecoration(
                  color: index <= currentStep
                      ? Theme.of(context).colorScheme.primary
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '\u00C9tape ${currentStep + 1} sur $totalSteps',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.colorTextSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onSkip;

  const _WelcomeStep({
    required this.onStart,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('welcome-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.shopping_basket_outlined,
            color: Theme.of(context).colorScheme.primary,
            size: 30,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Bienvenue sur Caddely',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.colorTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Ta liste de courses intelligente pour pr\u00E9parer tes achats, suivre tes habitudes et comparer les prix utiles.',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: AppTheme.colorTextSecondary,
          ),
        ),
        const Spacer(),
        FilledButton(
          onPressed: onStart,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: const Text('Commencer'),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: onSkip,
            child: const Text('Passer pour l\'instant'),
          ),
        ),
      ],
    );
  }
}

class _PrimaryStoreStep extends StatelessWidget {
  final String? selectedStoreId;
  final ValueChanged<String> onSelected;

  const _PrimaryStoreStep({
    required this.selectedStoreId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('primary-store-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quel est ton magasin habituel ?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.colorTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Choisis le magasin qui te sert de r\u00E9f\u00E9rence la plupart du temps.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.colorTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: mockStores
                .map(
                  (store) => _SelectableTile(
                    label: store.name,
                    selected: selectedStoreId == store.id,
                    onTap: () => onSelected(store.id),
                    trailing: selectedStoreId == store.id
                        ? const Icon(Icons.check_circle, color: AppTheme.colorCheapest)
                        : null,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SecondaryStoresStep extends StatelessWidget {
  final Set<String> availableStoreIds;
  final Set<String> selectedStoreIds;
  final void Function(String storeId, bool selected) onToggle;

  const _SecondaryStoresStep({
    required this.availableStoreIds,
    required this.selectedStoreIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final stores = mockStores
        .where((store) => availableStoreIds.contains(store.id))
        .toList();

    return Column(
      key: const ValueKey('secondary-stores-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quels autres magasins veux-tu comparer ?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.colorTextPrimary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Caddely comparera seulement les magasins o\u00F9 tu es pr\u00EAt \u00E0 aller.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.colorTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            children: stores
                .map(
                  (store) => CheckboxListTile(
                    value: selectedStoreIds.contains(store.id),
                    contentPadding: EdgeInsets.zero,
                    title: Text(store.name),
                    onChanged: (value) => onToggle(store.id, value ?? false),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _ReadyStep extends StatelessWidget {
  final bool storesOnly;

  const _ReadyStep({required this.storesOnly});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('ready-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Text(
          storesOnly ? 'Configuration mise \u00E0 jour' : 'Caddely est pr\u00EAt',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.colorTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          storesOnly
              ? 'Tes magasins favoris sont enregistr\u00E9s. Tu peux continuer \u00E0 comparer ton panier selon tes pr\u00E9f\u00E9rences.'
              : 'Tu peux maintenant cr\u00E9er ta liste, cocher les produits pris et comparer ton panier avec tes magasins favoris.',
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: AppTheme.colorTextSecondary,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  final int currentStep;
  final bool isSubmitting;
  final bool canContinue;
  final VoidCallback? onBack;
  final VoidCallback onContinue;

  const _BottomActions({
    required this.currentStep,
    required this.isSubmitting,
    required this.canContinue,
    required this.onBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null)
          Expanded(
            child: OutlinedButton(
              onPressed: isSubmitting ? null : onBack,
              child: const Text('Retour'),
            ),
          ),
        if (onBack != null) const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: !canContinue || isSubmitting ? null : onContinue,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(currentStep == 3 ? 'Voir ma liste' : 'Continuer'),
          ),
        ),
      ],
    );
  }
}

class _SelectableTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SelectableTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final trailingWidgets =
        trailing == null ? const <Widget>[] : <Widget>[trailing!];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? Theme.of(context).colorScheme.primary.withAlpha(14)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : AppTheme.colorBorder,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.colorTextPrimary,
                    ),
                  ),
                ),
                ...trailingWidgets,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
