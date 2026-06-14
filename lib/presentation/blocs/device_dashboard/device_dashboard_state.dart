part of 'device_dashboard_bloc.dart';

enum DashboardStatus { initial, loading, success, failure }

class DeviceDashboardState extends Equatable {
  const DeviceDashboardState({
    required this.deviceId,
    this.status = DashboardStatus.initial,
    this.summary,
    this.vitals,
    this.wellness,
    this.activity,
    this.isOffline = false,
    this.realtimeOpen = false,
    this.liveCount = 0,
    this.lastLiveAt,
    this.errorMessage,
  });

  final String deviceId;
  final DashboardStatus status;
  final DeviceSummary? summary;
  final Vitals? vitals;
  final Wellness? wellness;
  final Activity? activity;
  final bool isOffline;
  final bool realtimeOpen;
  final int liveCount;
  final DateTime? lastLiveAt;
  final String? errorMessage;

  LatestSnapshot? get latest => summary?.latest;

  /// True when actual realtime sample pushes have been received recently
  /// (not just an open heartbeat-only connection).
  bool get isLive {
    if (liveCount == 0 || lastLiveAt == null) return false;
    return DateTime.now().difference(lastLiveAt!) < const Duration(seconds: 90);
  }

  DeviceDashboardState copyWith({
    DashboardStatus? status,
    DeviceSummary? summary,
    Vitals? vitals,
    Wellness? wellness,
    Activity? activity,
    bool? isOffline,
    bool? realtimeOpen,
    int? liveCount,
    DateTime? lastLiveAt,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DeviceDashboardState(
      deviceId: deviceId,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      vitals: vitals ?? this.vitals,
      wellness: wellness ?? this.wellness,
      activity: activity ?? this.activity,
      isOffline: isOffline ?? this.isOffline,
      realtimeOpen: realtimeOpen ?? this.realtimeOpen,
      liveCount: liveCount ?? this.liveCount,
      lastLiveAt: lastLiveAt ?? this.lastLiveAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        deviceId,
        status,
        summary,
        vitals,
        wellness,
        activity,
        isOffline,
        realtimeOpen,
        liveCount,
        lastLiveAt,
        errorMessage,
      ];
}
