part of 'alarms_bloc.dart';

enum AlarmsStatus { initial, loading, success, failure }

class AlarmsState extends Equatable {
  const AlarmsState({
    this.status = AlarmsStatus.initial,
    this.alarms = const [],
    this.typeFilter,
    this.isOffline = false,
    this.errorMessage,
  });

  final AlarmsStatus status;
  final List<AlarmRow> alarms;
  final String? typeFilter;
  final bool isOffline;
  final String? errorMessage;

  int get criticalCount => alarms.where((a) => a.isSos || a.isFall).length;

  AlarmsState copyWith({
    AlarmsStatus? status,
    List<AlarmRow>? alarms,
    String? typeFilter,
    bool setFilter = false,
    bool? isOffline,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AlarmsState(
      status: status ?? this.status,
      alarms: alarms ?? this.alarms,
      typeFilter: setFilter ? typeFilter : this.typeFilter,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        alarms,
        typeFilter,
        isOffline,
        errorMessage,
      ];
}
