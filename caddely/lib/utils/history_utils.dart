bool shouldIgnoreRepeatedPurchase({
  required DateTime now,
  required DateTime lastPurchasedAt,
  required Duration duplicateWindow,
}) {
  return now.difference(lastPurchasedAt) < duplicateWindow;
}
