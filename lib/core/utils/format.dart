/// Whole numbers stay integers; everything else keeps one decimal.
String formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}
