part of 'dashboard_bloc.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => const [];
}

class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

class DashboardRefreshed extends DashboardEvent {
  const DashboardRefreshed({this.silent = false});

  final bool silent;

  @override
  List<Object?> get props => [silent];
}

class DashboardAlertResolved extends DashboardEvent {
  const DashboardAlertResolved(this.alertId);

  final String alertId;

  @override
  List<Object?> get props => [alertId];
}

/// Internal: a fresh summary produced by a reading sync.
class DashboardSummaryEmitted extends DashboardEvent {
  const DashboardSummaryEmitted(this.summary);

  final DashboardSummaryModel summary;

  @override
  List<Object?> get props => [summary];
}

/// Internal: updated settings produced by a settings save.
class DashboardSettingsApplied extends DashboardEvent {
  const DashboardSettingsApplied(this.settings);

  final HealthSettingsModel settings;

  @override
  List<Object?> get props => [settings];
}
