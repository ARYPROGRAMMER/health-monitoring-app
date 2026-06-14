import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/device_models.dart';
import '../../../data/repositories/health_repository.dart';
import '../../../data/services/realtime_service.dart';

part 'device_dashboard_event.dart';
part 'device_dashboard_state.dart';

/// Drives the live dashboard for one device: loads summary + vitals + wellness
/// + activity in parallel, keeps the latest snapshot updating in realtime from
/// the device SSE stream, and polls as a fallback. Each [LiveUpdate] is merged
/// field-by-field into the snapshot so the hero numbers tick instantly.
class DeviceDashboardBloc extends Bloc<DeviceDashboardEvent, DeviceDashboardState> {
  DeviceDashboardBloc({
    required HealthRepository repository,
    required String deviceId,
  })  : _repo = repository,
        super(DeviceDashboardState(deviceId: deviceId)) {
    on<DashboardStarted>(_onStarted);
    on<DashboardRefreshed>(_onRefreshed);
    on<DashboardLiveUpdate>(_onLive);
    on<DashboardRealtimeOpen>(_onRealtimeOpen);
  }

  final HealthRepository _repo;
  Timer? _pollTimer;
  RealtimeChannel? _channel;
  StreamSubscription<LiveUpdate>? _updateSub;
  StreamSubscription<bool>? _openSub;
  bool _refreshing = false;

  String get _id => state.deviceId;

  void _onStarted(DashboardStarted event, Emitter<DeviceDashboardState> emit) {
    _pollTimer ??= Timer.periodic(
      AppConfig.pollInterval,
      (_) => add(const DashboardRefreshed(silent: true)),
    );
    _channel ??= _repo.deviceChannel(_id)..connect();
    _updateSub ??= _channel!.updates.listen((u) => add(DashboardLiveUpdate(u)));
    _openSub ??= _channel!.open.listen((o) => add(DashboardRealtimeOpen(o)));
    add(const DashboardRefreshed());
  }

  Future<void> _onRefreshed(
    DashboardRefreshed event,
    Emitter<DeviceDashboardState> emit,
  ) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!event.silent && state.summary == null) {
      emit(state.copyWith(status: DashboardStatus.loading));
    }
    try {
      final results = await Future.wait([
        _repo.summary(_id),
        _repo.vitals(_id),
        _repo.wellness(_id),
        _repo.activity(_id),
      ]);
      emit(state.copyWith(
        status: DashboardStatus.success,
        summary: results[0] as DeviceSummary?,
        vitals: results[1] as Vitals,
        wellness: results[2] as Wellness,
        activity: results[3] as Activity,
        isOffline: false,
        clearError: true,
      ));
    } catch (e) {
      if (state.summary != null) {
        emit(state.copyWith(isOffline: true));
      } else {
        emit(state.copyWith(
          status: DashboardStatus.failure,
          errorMessage: e.toString(),
        ));
      }
    } finally {
      _refreshing = false;
    }
  }

  void _onLive(DashboardLiveUpdate event, Emitter<DeviceDashboardState> emit) {
    if (event.update.deviceId != _id) return;
    final current = state.summary;
    if (current == null) return;
    emit(state.copyWith(
      summary: current.withLatest(current.latest.merge(event.update.fields)),
      liveCount: state.liveCount + 1,
      lastLiveAt: DateTime.now(),
    ));
  }

  void _onRealtimeOpen(
    DashboardRealtimeOpen event,
    Emitter<DeviceDashboardState> emit,
  ) {
    emit(state.copyWith(realtimeOpen: event.open));
  }

  /// Refresh that resolves when the bloc settles (for RefreshIndicator).
  Future<void> refreshAndWait() async {
    add(const DashboardRefreshed(silent: true));
    await stream
        .firstWhere((s) => s.status != DashboardStatus.loading)
        .timeout(const Duration(seconds: 8), onTimeout: () => state);
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _updateSub?.cancel();
    _openSub?.cancel();
    _channel?.dispose();
    return super.close();
  }
}
