String formatRecipeIngredientQuantity(double? quantity) {
  if (quantity == null) {
    return '';
  }

  if (_isNearlyEqual(quantity, 0.25)) {
    return '1/4';
  }
  if (_isNearlyEqual(quantity, 0.5)) {
    return '1/2';
  }
  if (_isNearlyEqual(quantity, 0.75)) {
    return '3/4';
  }

  if (quantity == quantity.roundToDouble()) {
    return quantity.toInt().toString();
  }

  final asString = quantity.toStringAsFixed(2);
  return asString.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

String formatRecipeIngredientUnit(
  String unit, {
  double? quantity,
}) {
  final trimmed = unit.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final normalized = _normalizeToken(trimmed);
  final isPlural = quantity != null && quantity > 1;

  switch (normalized) {
    case 'sachet':
    case 'sachets':
      return 'sachet';
    case 'pincee':
    case 'pincees':
      return 'pincee'.replaceAll('ee', 'ée');
    case 'oeuf':
    case 'oeufs':
      return isPlural ? 'Oeufs'.replaceFirst('Oe', 'Œ') : 'Oeuf'.replaceFirst('Oe', 'Œ');
    case 'casoupe':
    case 'casoupes':
      return 'c. a soupe'.replaceFirst('a', 'à');
    case 'cacafe':
    case 'cacafes':
      return 'c. a cafe'.replaceFirst('a', 'à').replaceFirst('cafe', 'café');
    default:
      return trimmed;
  }
}

String formatRecipeIngredientName(
  String name, {
  double? quantity,
}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '';
  }

  final normalized = _normalizeToken(trimmed);
  switch (normalized) {
    case 'oeuf':
      return 'Oeuf'.replaceFirst('Oe', 'Œ');
    case 'oeufs':
      return quantity != null && quantity > 1
          ? 'Oeufs'.replaceFirst('Oe', 'Œ')
          : 'Oeuf'.replaceFirst('Oe', 'Œ');
    case 'cremefraiche':
      return 'Crème fraîche';
    case 'sucrevanille':
      return 'Sucre vanillé';
    case 'pates':
      return 'Pâtes';
    case 'cafe':
      return 'Café';
    default:
      return trimmed;
  }
}

String formatRecipeIngredientAmount({
  required double? quantity,
  required String unit,
}) {
  final formattedQuantity = formatRecipeIngredientQuantity(quantity);
  final formattedUnit = formatRecipeIngredientUnit(
    unit,
    quantity: quantity,
  );

  if (formattedQuantity.isEmpty) {
    return formattedUnit;
  }
  if (formattedUnit.isEmpty) {
    return formattedQuantity;
  }
  return '$formattedQuantity $formattedUnit';
}

String formatRecipeIngredientLabel({
  required String name,
  required double? quantity,
  required String unit,
}) {
  final amount = formatRecipeIngredientAmount(
    quantity: quantity,
    unit: unit,
  );
  final formattedName = formatRecipeIngredientName(
    name,
    quantity: quantity,
  );

  if (amount.isEmpty) {
    return formattedName;
  }
  if (formattedName.isEmpty) {
    return amount;
  }
  return '$amount $formattedName';
}

String formatRecipeIngredientNameForGrocery({
  required String name,
  required double? quantity,
}) {
  return formatRecipeIngredientName(
    name,
    quantity: quantity,
  );
}

bool _isNearlyEqual(double a, double b) {
  return (a - b).abs() < 0.001;
}

String _normalizeToken(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('(s)', 's')
      .replaceAll('œ', 'oe')
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ô', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}
