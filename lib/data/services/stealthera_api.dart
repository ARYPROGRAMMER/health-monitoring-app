import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import '../../core/config/app_config.dart';
import '../models/device_models.dart';

/// Common query parameters accepted by every series endpoint.
class SeriesQuery {
  const SeriesQuery({
    this.date,
    this.days,
    this.from,
    this.to,
    this.limit,
    this.granularity,
    this.order,
  });

  /// `YYYY-MM-DD` single day (display tz).
  final String? date;
  final int? days;
  final DateTime? from;
  final DateTime? to;
  final int? limit;

  /// raw | minute | hour | day
  final String? granularity;

  /// asc | desc
  final String? order;

  /// Bare query: backend returns the latest day with data.
  static const latest = SeriesQuery();

  Map<String, dynamic> toParams() {
    final p = <String, dynamic>{};
    if (date != null) p['date'] = date;
    if (days != null) p['days'] = days;
    if (from != null) p['from'] = from!.toUtc().toIso8601String();
    if (to != null) p['to'] = to!.toUtc().toIso8601String();
    if (limit != null) p['limit'] = limit;
    if (granularity != null) p['granularity'] = granularity;
    if (order != null) p['order'] = order;
    return p;
  }
}

/// Thin, typed client over the Stealthera client API (`/v1/api`).
class StealtheraApi {
  StealtheraApi({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: AppConfig.requestTimeout,
                receiveTimeout: AppConfig.requestTimeout,
                headers: {
                  'Accept': 'application/json',
                  if (AppConfig.apiKey.isNotEmpty) 'X-API-Key': AppConfig.apiKey,
                },
              ),
            ) {
    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        logPrint: (o) => developer.log(o.toString(), name: 'StealtheraApi'),
        retries: 2,
        retryDelays: const [Duration(seconds: 1), Duration(seconds: 3)],
      ),
    );
    if (AppConfig.verboseLogging) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false),
      );
    }
  }

  final Dio _dio;

  String get _tz => AppConfig.timezone;

  Map<String, dynamic> _withTz([Map<String, dynamic>? extra]) =>
      {'tz': _tz, ...?extra};

  Future<dynamic> _get(String path, {Map<String, dynamic>? params}) async {
    final res = await _dio.get<dynamic>(path, queryParameters: _withTz(params));
    return res.data;
  }

  // ---- Fleet -------------------------------------------------------------

  Future<List<DeviceRow>> healthData({String? search}) async {
    final data = await _get('/health-data', params: {
      if (search != null && search.isNotEmpty) 'search': search,
    });
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => DeviceRow.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  Future<FleetStats> stats() async {
    final data = await _get('/stats');
    return data is Map
        ? FleetStats.fromJson(Map<String, dynamic>.from(data))
        : FleetStats.empty;
  }

  Future<List<AlarmRow>> alarms({String? deviceId, String? type, int limit = 200}) async {
    final data = await _get('/alarms', params: {
      if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
      if (type != null && type.isNotEmpty) 'type': type,
      'limit': limit,
    });
    return _alarmList(data);
  }

  // ---- Device ------------------------------------------------------------

  Future<DeviceSummary?> deviceSummary(String id) async {
    try {
      final data = await _get('/device/$id');
      return data is Map
          ? DeviceSummary.fromJson(Map<String, dynamic>.from(data))
          : null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<DeviceInfo> deviceInfo(String id) async {
    final data = await _get('/device/$id/info');
    return DeviceInfo.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<Vitals> vitals(String id, [SeriesQuery q = SeriesQuery.latest]) async {
    final data = await _get('/device/$id/vitals', params: q.toParams());
    return Vitals.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<Wellness> wellness(String id, [SeriesQuery q = SeriesQuery.latest]) async {
    final data = await _get('/device/$id/wellness', params: q.toParams());
    return Wellness.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<Activity> activity(String id, [SeriesQuery q = SeriesQuery.latest]) async {
    final data = await _get('/device/$id/activity', params: q.toParams());
    return Activity.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<MetricSeries> metricSeries(
    String id,
    String metricKey, [
    SeriesQuery q = SeriesQuery.latest,
  ]) async {
    final data = await _get('/device/$id/metrics/$metricKey', params: q.toParams());
    return MetricSeries.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<BodyTempSeries> bodyTemp(String id, [SeriesQuery q = SeriesQuery.latest]) async {
    final data = await _get('/device/$id/bodytemp', params: q.toParams());
    return BodyTempSeries.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<BloodPressureSeries> bloodPressure(
    String id, [
    SeriesQuery q = SeriesQuery.latest,
  ]) async {
    final data = await _get('/device/$id/bloodpressure', params: q.toParams());
    return BloodPressureSeries.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<SosData> sos(String id, [SeriesQuery q = SeriesQuery.latest]) async {
    final data = await _get('/device/$id/sos', params: q.toParams());
    return SosData.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<LocationTrack> location(String id, [SeriesQuery q = SeriesQuery.latest]) async {
    final data = await _get('/device/$id/location', params: q.toParams());
    return LocationTrack.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<EcgData> ecg(String id, [SeriesQuery q = SeriesQuery.latest]) async {
    final data = await _get('/device/$id/ecg', params: q.toParams());
    return EcgData.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<AlarmRow>> deviceAlarms(String id, {String? type, int limit = 200}) async {
    final data = await _get('/device/$id/alarms', params: {
      if (type != null && type.isNotEmpty) 'type': type,
      'limit': limit,
    });
    return _alarmList(data);
  }

  /// Service `/health` lives at the host root, not under `/v1/api`.
  Future<ApiHealth> health() async {
    final res = await _dio.getUri<dynamic>(
      Uri.parse('${AppConfig.apiHost}/health'),
      options: Options(validateStatus: (s) => s != null && s < 600),
    );
    return ApiHealth.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  List<AlarmRow> _alarmList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => AlarmRow.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    // Paginated envelope { items: [...] } fallback.
    if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .whereType<Map>()
          .map((e) => AlarmRow.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }
}
