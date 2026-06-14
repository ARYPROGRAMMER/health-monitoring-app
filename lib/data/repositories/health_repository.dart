import '../../core/constants/cache_keys.dart';
import '../models/device_models.dart';
import '../services/cache_service.dart';
import '../services/realtime_service.dart';
import '../services/stealthera_api.dart';

/// Single entry point the BLoC layer uses to read the Stealthera backend.
/// Wraps the typed [StealtheraApi], persists the active-device selection and an
/// offline copy of the fleet list, and mints realtime SSE channels.
class HealthRepository {
  HealthRepository({required StealtheraApi api, required CacheService cache})
      : _api = api,
        _cache = cache;

  final StealtheraApi _api;
  final CacheService _cache;

  // ---- Active device session --------------------------------------------

  String? get activeDeviceId => _cache.readString(CacheKeys.activeDevice);

  Future<void> setActiveDevice(String deviceId) =>
      _cache.writeString(CacheKeys.activeDevice, deviceId);

  // ---- Fleet -------------------------------------------------------------

  Future<List<DeviceRow>> devices({String? search}) async {
    final rows = await _api.healthData(search: search);
    if (search == null || search.isEmpty) {
      await _cache.writeJsonList(
        CacheKeys.devices,
        rows.map((r) => r.toJson()).toList(),
      );
    }
    return rows;
  }

  List<DeviceRow> cachedDevices() =>
      _cache.readJsonList(CacheKeys.devices).map(DeviceRow.fromJson).toList();

  Future<FleetStats> stats() => _api.stats();

  Future<List<AlarmRow>> alarms({String? deviceId, String? type, int limit = 200}) =>
      _api.alarms(deviceId: deviceId, type: type, limit: limit);

  Future<ApiHealth> apiHealth() => _api.health();

  // ---- Device ------------------------------------------------------------

  Future<DeviceSummary?> summary(String id) => _api.deviceSummary(id);
  Future<DeviceInfo> info(String id) => _api.deviceInfo(id);
  Future<Vitals> vitals(String id, [SeriesQuery q = SeriesQuery.latest]) =>
      _api.vitals(id, q);
  Future<Wellness> wellness(String id, [SeriesQuery q = SeriesQuery.latest]) =>
      _api.wellness(id, q);
  Future<Activity> activity(String id, [SeriesQuery q = SeriesQuery.latest]) =>
      _api.activity(id, q);
  Future<MetricSeries> metricSeries(String id, String key,
          [SeriesQuery q = SeriesQuery.latest]) =>
      _api.metricSeries(id, key, q);
  Future<BodyTempSeries> bodyTemp(String id, [SeriesQuery q = SeriesQuery.latest]) =>
      _api.bodyTemp(id, q);
  Future<BloodPressureSeries> bloodPressure(String id,
          [SeriesQuery q = SeriesQuery.latest]) =>
      _api.bloodPressure(id, q);
  Future<SosData> sos(String id, [SeriesQuery q = SeriesQuery.latest]) =>
      _api.sos(id, q);
  Future<LocationTrack> location(String id, [SeriesQuery q = SeriesQuery.latest]) =>
      _api.location(id, q);
  Future<EcgData> ecg(String id, [SeriesQuery q = SeriesQuery.latest]) =>
      _api.ecg(id, q);
  Future<List<AlarmRow>> deviceAlarms(String id, {String? type, int limit = 200}) =>
      _api.deviceAlarms(id, type: type, limit: limit);

  // ---- Realtime ----------------------------------------------------------

  RealtimeChannel deviceChannel(String id) => RealtimeChannel(deviceId: id);
  RealtimeChannel fleetChannel() => RealtimeChannel();
}
