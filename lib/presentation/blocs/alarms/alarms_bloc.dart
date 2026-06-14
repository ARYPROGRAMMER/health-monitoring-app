import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/device_models.dart';
import '../../../data/repositories/health_repository.dart';
import '../../../data/services/notification_service.dart';

part 'alarms_event.dart';
part 'alarms_state.dart';

class AlarmsBloc extends Bloc<AlarmsEvent, AlarmsState> {
  AlarmsBloc({required HealthRepository repository})
      : _repo = repository,
        super(const AlarmsState()) {
    on<AlarmsStarted>(_onStarted);
    on<AlarmsRefreshed>(_onRefreshed);
    on<AlarmsFilterChanged>(_onFilterChanged);
  }

  final HealthRepository _repo;
  Timer? _pollTimer;
  bool _refreshing = false;

  void _onStarted(AlarmsStarted event, Emitter<AlarmsState> emit) {
    _pollTimer ??= Timer.periodic(
      AppConfig.pollInterval,
      (_) => add(const AlarmsRefreshed(silent: true)),
    );
    add(const AlarmsRefreshed());
  }

  Future<void> _onRefreshed(
    AlarmsRefreshed event,
    Emitter<AlarmsState> emit,
  ) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!event.silent && state.alarms.isEmpty) {
      emit(state.copyWith(status: AlarmsStatus.loading));
    }
    try {
      final alarms = await _repo.alarms(type: state.typeFilter, limit: 500);
      await NotificationService.instance.showAlarms(alarms);
      emit(state.copyWith(
        status: AlarmsStatus.success,
        alarms: alarms,
        isOffline: false,
        clearError: true,
      ));
    } catch (e) {
      if (state.alarms.isNotEmpty) {
        emit(state.copyWith(isOffline: true, errorMessage: e.toString()));
      } else {
        emit(state.copyWith(
          status: AlarmsStatus.failure,
          errorMessage: e.toString(),
        ));
      }
    } finally {
      _refreshing = false;
    }
  }

  void _onFilterChanged(
    AlarmsFilterChanged event,
    Emitter<AlarmsState> emit,
  ) {
    emit(state.copyWith(typeFilter: event.type, setFilter: true));
    add(const AlarmsRefreshed());
  }

  Future<void> refreshAndWait() async {
    add(const AlarmsRefreshed());
    await stream
        .firstWhere((s) => s.status != AlarmsStatus.loading)
        .timeout(const Duration(seconds: 8), onTimeout: () => state);
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
