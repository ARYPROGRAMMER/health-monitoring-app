import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/device_models.dart';
import '../../../data/repositories/health_repository.dart';
import '../../../data/services/realtime_service.dart';

part 'devices_event.dart';
part 'devices_state.dart';

/// Owns the fleet: loads the device list, keeps it live via the fleet SSE
/// stream (with a polling fallback), tracks the active-device selection and
/// surfaces fleet stats for the header tiles.
class DevicesBloc extends Bloc<DevicesEvent, DevicesState> {
  DevicesBloc({required HealthRepository repository})
      : _repo = repository,
        super(DevicesState(activeDeviceId: repository.activeDeviceId)) {
    on<DevicesStarted>(_onStarted);
    on<DevicesRefreshed>(_onRefreshed);
    on<DevicesSearched>(_onSearched);
    on<DeviceSelected>(_onSelected);
    on<DevicesLiveUpdate>(_onLive);
    on<DevicesRealtimeOpen>(_onRealtimeOpen);
  }

  final HealthRepository _repo;
  Timer? _pollTimer;
  RealtimeChannel? _channel;
  StreamSubscription<LiveUpdate>? _updateSub;
  StreamSubscription<bool>? _openSub;
  bool _refreshing = false;

  Future<void> _onStarted(DevicesStarted event, Emitter<DevicesState> emit) async {
    final cached = _repo.cachedDevices();
    if (cached.isNotEmpty) {
      emit(state.copyWith(status: DevicesStatus.success, devices: cached));
    } else {
      emit(state.copyWith(status: DevicesStatus.loading));
    }

    _pollTimer ??= Timer.periodic(
      AppConfig.pollInterval,
      (_) => add(const DevicesRefreshed(silent: true)),
    );

    _channel ??= _repo.fleetChannel()..connect();
    _updateSub ??=
        _channel!.updates.listen((u) => add(DevicesLiveUpdate(u)));
    _openSub ??= _channel!.open.listen((o) => add(DevicesRealtimeOpen(o)));

    add(const DevicesRefreshed(silent: true));
  }

  Future<void> _onRefreshed(DevicesRefreshed event, Emitter<DevicesState> emit) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!event.silent && state.devices.isEmpty) {
      emit(state.copyWith(status: DevicesStatus.loading));
    }
    try {
      final results = await Future.wait([
        _repo.devices(),
        _repo.stats().catchError((_) => FleetStats.empty),
      ]);
      final devices = results[0] as List<DeviceRow>;
      final stats = results[1] as FleetStats;
      emit(state.copyWith(
        status: DevicesStatus.success,
        devices: devices,
        stats: stats,
        isOffline: false,
        clearError: true,
      ));
    } catch (e) {
      if (state.devices.isNotEmpty) {
        emit(state.copyWith(isOffline: true));
      } else {
        emit(state.copyWith(
          status: DevicesStatus.failure,
          errorMessage: e.toString(),
        ));
      }
    } finally {
      _refreshing = false;
    }
  }

  void _onSearched(DevicesSearched event, Emitter<DevicesState> emit) {
    emit(state.copyWith(search: event.query));
  }

  Future<void> _onSelected(DeviceSelected event, Emitter<DevicesState> emit) async {
    await _repo.setActiveDevice(event.deviceId);
    emit(state.copyWith(activeDeviceId: event.deviceId));
  }

  void _onLive(DevicesLiveUpdate event, Emitter<DevicesState> emit) {
    final id = event.update.deviceId;
    if (id.isEmpty) return;
    final next = state.devices
        .map((d) => d.deviceId == id ? d.applyLive(event.update.fields) : d)
        .toList();
    emit(state.copyWith(devices: next, lastLiveAt: DateTime.now()));
  }

  void _onRealtimeOpen(DevicesRealtimeOpen event, Emitter<DevicesState> emit) {
    emit(state.copyWith(realtimeOpen: event.open));
  }

  Future<void> refreshAndWait() async {
    add(const DevicesRefreshed());
    await stream
        .firstWhere((s) => s.status != DevicesStatus.loading)
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
