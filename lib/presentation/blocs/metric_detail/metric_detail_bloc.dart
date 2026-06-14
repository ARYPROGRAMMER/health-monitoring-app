import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/device_models.dart';
import '../../../data/models/metric_catalog.dart';
import '../../../data/repositories/health_repository.dart';
import '../../../data/services/realtime_service.dart';
import '../../../data/services/stealthera_api.dart';

part 'metric_detail_event.dart';
part 'metric_detail_state.dart';

enum MetricRange { day, week, month }

extension MetricRangeX on MetricRange {
  String get label => switch (this) {
        MetricRange.day => 'Day',
        MetricRange.week => 'Week',
        MetricRange.month => 'Month',
      };

  SeriesQuery get query => switch (this) {
        MetricRange.day => const SeriesQuery(granularity: 'raw'),
        MetricRange.week => const SeriesQuery(days: 7, granularity: 'hour'),
        MetricRange.month => const SeriesQuery(days: 30, granularity: 'day'),
      };
}

/// Backs the metric-detail screen for any [MetricSpec]: fetches the series for
/// the selected range, keeps the hero value ticking from the device SSE stream,
/// and polls the chart on the configured cadence.
class MetricDetailBloc extends Bloc<MetricDetailEvent, MetricDetailState> {
  MetricDetailBloc({
    required HealthRepository repository,
    required this.deviceId,
    required this.spec,
  })  : _repo = repository,
        super(const MetricDetailState()) {
    on<MetricStarted>(_onStarted);
    on<MetricRangeChanged>(_onRangeChanged);
    on<MetricRefreshed>(_onRefreshed);
    on<MetricLiveUpdate>(_onLive);
  }

  final HealthRepository _repo;
  final String deviceId;
  final MetricSpec spec;

  Timer? _pollTimer;
  RealtimeChannel? _channel;
  StreamSubscription<LiveUpdate>? _updateSub;

  void _onStarted(MetricStarted event, Emitter<MetricDetailState> emit) {
    _channel ??= _repo.deviceChannel(deviceId)..connect();
    _updateSub ??= _channel!.updates.listen((u) => add(MetricLiveUpdate(u)));
    _pollTimer ??= Timer.periodic(
      AppConfig.pollInterval,
      (_) => add(const MetricRefreshed(silent: true)),
    );
    add(const MetricRefreshed());
  }

  Future<void> _onRangeChanged(
    MetricRangeChanged event,
    Emitter<MetricDetailState> emit,
  ) async {
    emit(state.copyWith(range: event.range));
    await _load(emit, silent: false);
  }

  Future<void> _onRefreshed(
    MetricRefreshed event,
    Emitter<MetricDetailState> emit,
  ) =>
      _load(emit, silent: event.silent);

  Future<void> _load(Emitter<MetricDetailState> emit, {required bool silent}) async {
    if (!silent && state.status != MetricStatus.success) {
      emit(state.copyWith(status: MetricStatus.loading));
    }
    final q = state.range.query;
    try {
      switch (spec.source) {
        case MetricSource.bloodPressure:
          final bp = await _repo.bloodPressure(deviceId, q);
          emit(state.copyWith(
            status: MetricStatus.success,
            bloodPressure: bp,
            clearError: true,
          ));
        case MetricSource.bodyTemp:
          final t = await _repo.bodyTemp(deviceId, q);
          emit(state.copyWith(
            status: MetricStatus.success,
            series: t.core,
            skinSeries: t.skinSeries,
            clearError: true,
          ));
        case MetricSource.generic:
          final s = await _repo.metricSeries(deviceId, spec.key, q);
          emit(state.copyWith(
            status: MetricStatus.success,
            series: s,
            clearError: true,
          ));
      }
    } catch (e) {
      if (state.status != MetricStatus.success) {
        emit(state.copyWith(status: MetricStatus.failure, errorMessage: e.toString()));
      }
    }
  }

  void _onLive(MetricLiveUpdate event, Emitter<MetricDetailState> emit) {
    if (event.update.deviceId != deviceId) return;
    final v = event.update.fields[spec.field];
    if (v is num) {
      emit(state.copyWith(liveValue: v.toDouble(), lastLiveAt: DateTime.now()));
    }
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _updateSub?.cancel();
    _channel?.dispose();
    return super.close();
  }
}
