/// Formats a metric value: whole numbers stay integers, others keep 1 decimal.
String formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
}

/// Estimated active calories from a step count (~0.04 kcal/step).
double estimateCalories(double steps) => steps * 0.04;
