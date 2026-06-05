import 'package:flutter/material.dart';

import '../../../data/models/health_models.dart';
import '../../../core/utils/format.dart';

/// The four live metrics surfaced by the Fitbit-style design.
enum MetricKind { heart, steps, spo2, calories }

extension MetricKindX on MetricKind {
  String get title => switch (this) {
    MetricKind.heart => 'Heart',
    MetricKind.steps => 'Steps',
    MetricKind.spo2 => 'Blood Oxygen',
    MetricKind.calories => 'Calories',
  };

  String get unit => switch (this) {
    MetricKind.heart => 'BPM',
    MetricKind.steps => 'Steps',
    MetricKind.spo2 => 'O₂',
    MetricKind.calories => 'Kcal',
  };

  String get illustration => switch (this) {
    MetricKind.heart => 'heart',
    MetricKind.steps => 'steps',
    MetricKind.spo2 => 'spo2',
    MetricKind.calories => 'calories',
  };

  IconData get icon => switch (this) {
    MetricKind.heart => Icons.favorite_rounded,
    MetricKind.steps => Icons.directions_run_rounded,
    MetricKind.spo2 => Icons.air_rounded,
    MetricKind.calories => Icons.local_fire_department_rounded,
  };

  /// The current value for this metric, or null when no reading exists.
  double? value(DashboardSummaryModel summary) => switch (this) {
    MetricKind.heart => summary.heartRate?.value,
    MetricKind.steps => summary.activity?.value,
    MetricKind.spo2 => summary.spo2?.value,
    MetricKind.calories => summary.activity == null
        ? null
        : estimateCalories(summary.activity!.value),
  };

  List<TrendPointModel> trend(DashboardSummaryModel summary) => switch (this) {
    MetricKind.heart => summary.heartRateTrend,
    MetricKind.steps => summary.activityTrend,
    MetricKind.spo2 => summary.spo2Trend,
    MetricKind.calories => summary.activityTrend,
  };

  /// Display string for the current value (mono numerals).
  String display(DashboardSummaryModel summary) {
    final v = value(summary);
    if (v == null) return '--';
    if (this == MetricKind.calories) return v.toStringAsFixed(2);
    return formatNumber(v);
  }
}
