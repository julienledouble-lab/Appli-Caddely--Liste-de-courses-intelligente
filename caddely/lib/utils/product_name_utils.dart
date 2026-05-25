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
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ä': 'a',
    'æ': 'ae',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ô': 'o',
    'ö': 'o',
    'œ': 'oe',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ÿ': 'y',
    'À': 'a',
    'Á': 'a',
    'Â': 'a',
    'Ä': 'a',
    'Æ': 'ae',
    'Ç': 'c',
    'È': 'e',
    'É': 'e',
    'Ê': 'e',
    'Ë': 'e',
    'Î': 'i',
    'Ï': 'i',
    'Ñ': 'n',
    'Ô': 'o',
    'Ö': 'o',
    'Œ': 'oe',
    'Ù': 'u',
    'Ú': 'u',
    'Û': 'u',
    'Ü': 'u',
    // Older mojibake forms still tolerated in legacy stored data.
    'Ã ': 'a',
    'Ã¡': 'a',
    'Ã¢': 'a',
    'Ã¤': 'a',
    'Ã¦': 'ae',
    'Ã§': 'c',
    'Ã¨': 'e',
    'Ã©': 'e',
    'Ãª': 'e',
    'Ã«': 'e',
    'Ã®': 'i',
    'Ã¯': 'i',
    'Ã±': 'n',
    'Ã´': 'o',
    'Ã¶': 'o',
    'Å“': 'oe',
    'Ã¹': 'u',
    'Ãº': 'u',
    'Ã»': 'u',
    'Ã¼': 'u',
    'Ã¿': 'y',
    'Ã€': 'a',
    'Ã': 'a',
    'Ã‚': 'a',
    'Ã„': 'a',
    'Ã†': 'ae',
    'Ã‡': 'c',
    'Ãˆ': 'e',
    'Ã‰': 'e',
    'ÃŠ': 'e',
    'Ã‹': 'e',
    'ÃŽ': 'i',
    'Ã': 'i',
    'Ã‘': 'n',
    'Ã”': 'o',
    'Ã–': 'o',
    'Å’': 'oe',
    'Ã™': 'u',
    'Ãš': 'u',
    'Ã›': 'u',
    'Ãœ': 'u',
  };

  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(map[char] ?? char);
  }
  return buffer.toString();
}

String normalizeForSearch(String value) => stripAccents(normalizeProductName(value));

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
