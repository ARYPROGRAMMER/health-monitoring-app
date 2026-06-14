part of 'metric_detail_bloc.dart';

enum MetricStatus { initial, loading, success, failure }

class MetricDetailState extends Equatable {
  const MetricDetailState({
    this.status = MetricStatus.initial,
    this.range = MetricRange.day,
    this.series,
    this.skinSeries = const [],
    this.bloodPressure,
    this.liveValue,
    this.lastLiveAt,
    this.errorMessage,
  });

  final MetricStatus status;
  final MetricRange range;

  /// Single-value (or body-temp core) series.
  final MetricSeries? series;

  /// Skin-temperature overlay (body-temp only).
  final List<TimeValue> skinSeries;

  /// Blood-pressure dual series (BP only).
  final BloodPressureSeries? bloodPressure;

  /// Latest value pushed over realtime (hero only).
  final double? liveValue;
  final DateTime? lastLiveAt;
  final String? errorMessage;

  bool get isLive =>
      lastLiveAt != null &&
      DateTime.now().difference(lastLiveAt!) < const Duration(seconds: 90);

  MetricDetailState copyWith({
    MetricStatus? status,
    MetricRange? range,
    MetricSeries? series,
    List<TimeValue>? skinSeries,
    BloodPressureSeries? bloodPressure,
    double? liveValue,
    DateTime? lastLiveAt,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MetricDetailState(
      status: status ?? this.status,
      range: range ?? this.range,
      series: series ?? this.series,
      skinSeries: skinSeries ?? this.skinSeries,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      liveValue: liveValue ?? this.liveValue,
      lastLiveAt: lastLiveAt ?? this.lastLiveAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        range,
        series,
        skinSeries,
        bloodPressure,
        liveValue,
        lastLiveAt,
        errorMessage,
      ];
}
