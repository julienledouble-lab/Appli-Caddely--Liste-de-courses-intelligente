String normalizeProductName(String value) {
  final collapsed = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  return collapsed.toLowerCase();
}

String cleanProductName(String value) {
  final collapsed = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (collapsed.isEmpty) {
    return '';
  }

  final first = collapsed.substring(0, 1).toUpperCase();
  final rest = collapsed.substring(1);
  return '$first$rest';
}

String stripAccents(String input) {
  const map = <String, String>{
    'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a',
    'æ': 'ae',
    'ç': 'c',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i',
    'ñ': 'n',
    'ô': 'o', 'ö': 'o',
    'œ': 'oe',
    'ù': 'u', 'û': 'u', 'ü': 'u',
    'ÿ': 'y',
  };
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(map[char] ?? char);
  }
  return buffer.toString();
}

/// Normalise pour la recherche floue : minuscules + suppression des accents.
/// Ne pas utiliser pour la déduplication — utiliser [normalizeProductName].
String normalizeForSearch(String value) =>
    stripAccents(normalizeProductName(value));

bool productMatches(String candidate, String query) {
  final normalizedCandidate = normalizeForSearch(candidate);
  final normalizedQuery = normalizeForSearch(query);

  if (normalizedCandidate.isEmpty || normalizedQuery.isEmpty) {
    return false;
  }

  return normalizedCandidate == normalizedQuery ||
      normalizedCandidate.contains(normalizedQuery) ||
      normalizedQuery.contains(normalizedCandidate);
}
