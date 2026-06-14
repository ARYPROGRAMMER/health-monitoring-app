part of 'devices_bloc.dart';

sealed class DevicesEvent extends Equatable {
  const DevicesEvent();

  @override
  List<Object?> get props => const [];
}

class DevicesStarted extends DevicesEvent {
  const DevicesStarted();
}

class DevicesRefreshed extends DevicesEvent {
  const DevicesRefreshed({this.silent = false});

  final bool silent;

  @override
  List<Object?> get props => [silent];
}

class DevicesSearched extends DevicesEvent {
  const DevicesSearched(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class DeviceSelected extends DevicesEvent {
  const DeviceSelected(this.deviceId);

  final String deviceId;

  @override
  List<Object?> get props => [deviceId];
}

class DevicesLiveUpdate extends DevicesEvent {
  const DevicesLiveUpdate(this.update);

  final LiveUpdate update;

  @override
  List<Object?> get props => [update.deviceId, update.fields];
}

class DevicesRealtimeOpen extends DevicesEvent {
  const DevicesRealtimeOpen(this.open);

  final bool open;

  @override
  List<Object?> get props => [open];
}
