part of 'devices_bloc.dart';

enum DevicesStatus { initial, loading, success, failure }

class DevicesState extends Equatable {
  const DevicesState({
    this.status = DevicesStatus.initial,
    this.devices = const [],
    this.stats = FleetStats.empty,
    this.activeDeviceId,
    this.search = '',
    this.isOffline = false,
    this.realtimeOpen = false,
    this.errorMessage,
    this.lastLiveAt,
  });

  final DevicesStatus status;
  final List<DeviceRow> devices;
  final FleetStats stats;
  final String? activeDeviceId;
  final String search;
  final bool isOffline;
  final bool realtimeOpen;
  final String? errorMessage;
  final DateTime? lastLiveAt;

  /// Devices filtered by the live search query (id / nickname / model).
  List<DeviceRow> get filtered {
    if (search.trim().isEmpty) return devices;
    final q = search.toLowerCase();
    return devices
        .where((d) =>
            d.deviceId.toLowerCase().contains(q) ||
            d.nickname.toLowerCase().contains(q) ||
            d.model.toLowerCase().contains(q))
        .toList();
  }

  DeviceRow? get activeDevice {
    for (final d in devices) {
      if (d.deviceId == activeDeviceId) return d;
    }
    return null;
  }

  DevicesState copyWith({
    DevicesStatus? status,
    List<DeviceRow>? devices,
    FleetStats? stats,
    String? activeDeviceId,
    String? search,
    bool? isOffline,
    bool? realtimeOpen,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastLiveAt,
  }) {
    return DevicesState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      stats: stats ?? this.stats,
      activeDeviceId: activeDeviceId ?? this.activeDeviceId,
      search: search ?? this.search,
      isOffline: isOffline ?? this.isOffline,
      realtimeOpen: realtimeOpen ?? this.realtimeOpen,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastLiveAt: lastLiveAt ?? this.lastLiveAt,
    );
  }

  @override
  List<Object?> get props => [
        status,
        devices,
        stats,
        activeDeviceId,
        search,
        isOffline,
        realtimeOpen,
        errorMessage,
        lastLiveAt,
      ];
}
