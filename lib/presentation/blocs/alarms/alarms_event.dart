part of 'alarms_bloc.dart';

sealed class AlarmsEvent extends Equatable {
  const AlarmsEvent();

  @override
  List<Object?> get props => const [];
}

class AlarmsStarted extends AlarmsEvent {
  const AlarmsStarted();
}

class AlarmsRefreshed extends AlarmsEvent {
  const AlarmsRefreshed({this.silent = false});

  final bool silent;

  @override
  List<Object?> get props => [silent];
}

class AlarmsFilterChanged extends AlarmsEvent {
  const AlarmsFilterChanged(this.type);

  final String? type;

  @override
  List<Object?> get props => [type];
}
