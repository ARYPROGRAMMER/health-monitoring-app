import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/health_models.dart';
import '../../../data/repositories/health_repository.dart';
import '../../../data/services/notification_service.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

/// Drives the health dashboard: hydrates from cache, polls the backend, applies
/// reading syncs / settings saves / alert resolutions, and falls back to cached
/// data when the backend is unreachable.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({required HealthRepository repository})
    : _repository = repository,
      super(const DashboardState()) {
    on<DashboardStarted>(_onStarted);
    on<DashboardRefreshed>(_onRefreshed);
    on<DashboardAlertResolved>(_onAlertResolved);
    on<DashboardSummaryEmitted>(_onSummaryEmitted);
    on<DashboardSettingsApplied>(_onSettingsApplied);
  }

  final HealthRepository _repository;
  Timer? _pollTimer;
  bool _refreshing = false;

  /// Syncs a single reading and surfaces failures to the caller (the sheet).
  Future<void> syncReading(HealthReadingModel reading) async {
    final summary = await _repository.syncReading(reading);
    if (summary.settings.notificationsEnabled) {
      await NotificationService.instance.showHealthAlerts(summary.activeAlerts);
    }
    add(DashboardSummaryEmitted(summary));
  }

  /// Persists settings and surfaces failures to the caller (settings screen).
  Future<void> saveSettings(HealthSettingsModel settings) async {
    final updated = await _repository.updateSettings(settings);
    add(DashboardSettingsApplied(updated));
  }

  void _onStarted(DashboardStarted event, Emitter<DashboardState> emit) {
    final cached = _repository.cachedDashboard();
    emit(
      state.copyWith(
        status: cached != null
            ? DashboardStatus.success
            : DashboardStatus.loading,
        summary: cached,
      ),
    );
    _pollTimer ??= Timer.periodic(
      AppConfig.pollInterval,
      (_) => add(const DashboardRefreshed(silent: true)),
    );
    add(const DashboardRefreshed(silent: true));
  }

  Future<void> _onRefreshed(
    DashboardRefreshed event,
    Emitter<DashboardState> emit,
  ) async {
    if (_refreshing) return;
    _refreshing = true;
    final previous = state.summary;

    if (!event.silent) {
      emit(state.copyWith(status: DashboardStatus.loading));
    }

    try {
      final summary = await _repository.fetchDashboard();
      if (summary.settings.notificationsEnabled) {
        await NotificationService.instance.showHealthAlerts(
          summary.activeAlerts,
        );
      }
      emit(
        DashboardState(status: DashboardStatus.success, summary: summary),
      );
    } catch (error) {
      final cached = _repository.cachedDashboard();
      if (cached != null || previous != null) {
        emit(
          DashboardState(
            status: DashboardStatus.success,
            summary: (cached ?? previous!).copyWith(
              isOffline: true,
              errorMessage:
                  'Showing cached health data while the backend is unavailable.',
            ),
          ),
        );
      } else {
        emit(
          DashboardState(
            status: DashboardStatus.failure,
            errorMessage: error.toString(),
          ),
        );
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _onAlertResolved(
    DashboardAlertResolved event,
    Emitter<DashboardState> emit,
  ) async {
    final current = state.summary;
    if (current == null) return;

    try {
      await _repository.resolveAlert(event.alertId);
      emit(
        state.copyWith(
          summary: current.copyWith(
            alerts: current.alerts
                .map(
                  (alert) =>
                      alert.id == event.alertId ? _resolve(alert) : alert,
                )
                .toList(),
            activeAlerts: current.activeAlerts
                .where((alert) => alert.id != event.alertId)
                .toList(),
          ),
        ),
      );
      add(const DashboardRefreshed(silent: true));
    } catch (_) {
      // Keep current state; the backend will reconcile on next refresh.
    }
  }

  void _onSummaryEmitted(
    DashboardSummaryEmitted event,
    Emitter<DashboardState> emit,
  ) {
    emit(DashboardState(status: DashboardStatus.success, summary: event.summary));
  }

  void _onSettingsApplied(
    DashboardSettingsApplied event,
    Emitter<DashboardState> emit,
  ) {
    final current = state.summary;
    if (current != null) {
      emit(state.copyWith(summary: current.copyWith(settings: event.settings)));
    }
    add(const DashboardRefreshed(silent: true));
  }

  HealthAlertModel _resolve(HealthAlertModel alert) {
    return HealthAlertModel(
      id: alert.id,
      type: alert.type,
      severity: alert.severity,
      title: alert.title,
      message: alert.message,
      metricValue: alert.metricValue,
      thresholdValue: alert.thresholdValue,
      status: 'resolved',
      createdAt: alert.createdAt,
      resolvedAt: DateTime.now(),
    );
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}

extension DashboardRefreshAwait on DashboardBloc {
  /// Triggers a refresh and resolves once the bloc settles — lets a
  /// [RefreshIndicator] keep spinning until the work actually finishes.
  Future<void> refreshAndWait() async {
    add(const DashboardRefreshed());
    await stream
        .firstWhere(
          (state) =>
              state.status == DashboardStatus.success ||
              state.status == DashboardStatus.failure,
        )
        .timeout(const Duration(seconds: 8), onTimeout: () => state);
  }
}
