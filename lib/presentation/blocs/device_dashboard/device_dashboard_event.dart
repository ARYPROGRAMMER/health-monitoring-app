part of 'device_dashboard_bloc.dart';

sealed class DeviceDashboardEvent extends Equatable {
  const DeviceDashboardEvent();

  @override
  List<Object?> get props => const [];
}

class DashboardStarted extends DeviceDashboardEvent {
  const DashboardStarted();
}

class DashboardRefreshed extends DeviceDashboardEvent {
  const DashboardRefreshed({this.silent = false});

  final bool silent;

  @override
  List<Object?> get props => [silent];
}

class DashboardLiveUpdate extends DeviceDashboardEvent {
  const DashboardLiveUpdate(this.update);

  final LiveUpdate update;

  @override
  List<Object?> get props => [update.deviceId, update.fields];
}

class DashboardRealtimeOpen extends DeviceDashboardEvent {
  const DashboardRealtimeOpen(this.open);

  final bool open;

  @override
  List<Object?> get props => [open];
}
