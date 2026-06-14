part of 'metric_detail_bloc.dart';

sealed class MetricDetailEvent extends Equatable {
  const MetricDetailEvent();

  @override
  List<Object?> get props => const [];
}

class MetricStarted extends MetricDetailEvent {
  const MetricStarted();
}

class MetricRangeChanged extends MetricDetailEvent {
  const MetricRangeChanged(this.range);

  final MetricRange range;

  @override
  List<Object?> get props => [range];
}

class MetricRefreshed extends MetricDetailEvent {
  const MetricRefreshed({this.silent = false});

  final bool silent;

  @override
  List<Object?> get props => [silent];
}

class MetricLiveUpdate extends MetricDetailEvent {
  const MetricLiveUpdate(this.update);

  final LiveUpdate update;

  @override
  List<Object?> get props => [update.deviceId, update.fields];
}
