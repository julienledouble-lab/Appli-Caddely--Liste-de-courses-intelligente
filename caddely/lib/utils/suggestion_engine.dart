import '../data/local_product_catalog.dart';
import '../models/habit_suggestion.dart';
import '../models/purchase_record.dart';
import 'product_name_utils.dart';

/// Construit la liste de suggestions pour le champ d'ajout.
///
/// Priorité :
/// 1. Produits de l'historique les plus fréquents (sortedHistory est pré-trié).
/// 2. Produits du catalogue local si l'historique ne remplit pas [limit]
///    (uniquement quand [query] est non vide).
///
/// Les produits déjà dans la liste active sont exclus via [excludedNames]
/// (noms normalisés via [normalizeProductName]).
List<HabitSuggestion> buildSuggestions({
  required List<PurchaseRecord> sortedHistory,
  required String query,
  required Set<String> excludedNames,
  int limit = 5,
}) {
  final trimmedQuery = query.trim();
  final result = <HabitSuggestion>[];

  // 1 — Historique (pré-trié par fréquence + récence)
  for (final record in sortedHistory) {
    if (result.length >= limit) break;
    final normalizedName = normalizeProductName(record.productName);
    if (excludedNames.contains(normalizedName)) continue;
    if (trimmedQuery.isNotEmpty &&
        !productMatches(record.productName, trimmedQuery)) {
      continue;
    }
    result.add(HabitSuggestion.fromRecord(record));
  }

  // 2 — Catalogue local : fallback quand requête active et résultats insuffisants
  if (trimmedQuery.isNotEmpty && result.length < limit) {
    final usedNames = <String>{
      ...excludedNames,
      ...result.map((s) => normalizeProductName(s.productName)),
    };
    for (final product in localProductCatalog) {
      if (result.length >= limit) break;
      final normalizedName = normalizeProductName(product.name);
      if (usedNames.contains(normalizedName)) continue;
      if (!productMatches(product.name, trimmedQuery)) continue;
      result.add(
        HabitSuggestion(
          productName: product.name,
          quantity: product.quantity,
          category: product.category,
          frequency: 0,
        ),
      );
    }
  }

  return result;
}
