// ignore_for_file: lines_longer_than_80_chars
//
// Typed models for the Stealthera client API (`/v1/api`).

double _d(Object? v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

int _i(Object? v, [int fallback = 0]) {
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String _s(Object? v, [String fallback = '']) =>
    v == null ? fallback : v.toString();

bool _b(Object? v) => v == true || v == 'true' || v == 1;

Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> _mapList(Object? v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];

class TimeValue {
  const TimeValue({required this.time, required this.value});

  final String time;
  final double value;

  factory TimeValue.fromJson(Map<String, dynamic> j) =>
      TimeValue(time: _s(j['time']), value: _d(j['value']));
}

class BpPoint {
  const BpPoint({required this.time, required this.systolic, required this.diastolic});

  final String time;
  final double systolic;
  final double diastolic;

  factory BpPoint.fromJson(Map<String, dynamic> j) => BpPoint(
        time: _s(j['time']),
        systolic: _d(j['systolic']),
        diastolic: _d(j['diastolic']),
      );
}

class WarningRecord {
  const WarningRecord({required this.time, required this.value});

  final String time;
  final String value;

  factory WarningRecord.fromJson(Map<String, dynamic> j) =>
      WarningRecord(time: _s(j['time']), value: _s(j['value']));
}

/// The shape returned by every single-value metric endpoint.
class MetricSeries {
  const MetricSeries({
    required this.deviceId,
    required this.date,
    required this.series,
    required this.average,
    required this.max,
    required this.min,
    required this.count,
    required this.unit,
    required this.warningRecords,
    required this.extra,
  });

  final String deviceId;
  final String date;
  final List<TimeValue> series;
  final double average;
  final double max;
  final double min;
  final int count;
  final String unit;
  final List<WarningRecord> warningRecords;
  final Map<String, String> extra;

  bool get isEmpty => series.isEmpty;
  bool get hasData => series.isNotEmpty;
  double? get latest => series.isEmpty ? null : series.last.value;

  factory MetricSeries.fromJson(Map<String, dynamic> j, {String unitFallback = ''}) {
    // `extra` may arrive as a nested object (generic endpoint) or be spread
    // across top-level keys (buildSimpleMetric). Capture both.
    final extra = <String, String>{};
    final nested = j['extra'];
    if (nested is Map) {
      nested.forEach((k, v) => extra['$k'] = '$v');
    }
    for (final key in const [
      'normalRange',
      'maleStandard',
      'femaleStandard',
    ]) {
      if (j[key] != null) extra[key] = _s(j[key]);
    }
    return MetricSeries(
      deviceId: _s(j['deviceId']),
      date: _s(j['date']),
      series: (j['series'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => TimeValue.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      average: _d(j['average']),
      max: _d(j['max']),
      min: _d(j['min']),
      count: _i(j['count']),
      unit: _s(j['unit'], unitFallback),
      warningRecords: _mapList(j['warningRecords'])
          .map(WarningRecord.fromJson)
          .toList(),
      extra: extra,
    );
  }

  static const empty = MetricSeries(
    deviceId: '',
    date: '',
    series: [],
    average: 0,
    max: 0,
    min: 0,
    count: 0,
    unit: '',
    warningRecords: [],
    extra: {},
  );
}

/// `/device/:id/bloodpressure` — dual systolic/diastolic series.
class BloodPressureSeries {
  const BloodPressureSeries({
    required this.deviceId,
    required this.date,
    required this.series,
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.warningRecords,
  });

  final String deviceId;
  final String date;
  final List<BpPoint> series;
  final double avgSystolic;
  final double avgDiastolic;
  final List<WarningRecord> warningRecords;

  bool get hasData => series.isNotEmpty;
  BpPoint? get latest => series.isEmpty ? null : series.last;

  factory BloodPressureSeries.fromJson(Map<String, dynamic> j) =>
      BloodPressureSeries(
        deviceId: _s(j['deviceId']),
        date: _s(j['date']),
        series: _mapList(j['series']).map(BpPoint.fromJson).toList(),
        avgSystolic: _d(j['avgSystolic']),
        avgDiastolic: _d(j['avgDiastolic']),
        warningRecords:
            _mapList(j['warningRecords']).map(WarningRecord.fromJson).toList(),
      );

  static const empty = BloodPressureSeries(
    deviceId: '',
    date: '',
    series: [],
    avgSystolic: 0,
    avgDiastolic: 0,
    warningRecords: [],
  );
}

/// Body temperature with an optional skin-temperature overlay.
class BodyTempSeries {
  const BodyTempSeries({
    required this.core,
    required this.skinSeries,
    required this.skinAverage,
  });

  final MetricSeries core;
  final List<TimeValue> skinSeries;
  final double skinAverage;

  factory BodyTempSeries.fromJson(Map<String, dynamic> j) => BodyTempSeries(
        core: MetricSeries.fromJson(j, unitFallback: 'C'),
        skinSeries: (j['skinSeries'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => TimeValue.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        skinAverage: _d(j['skinAverage']),
      );
}

/// The rolled-up `latest` snapshot of a device's most recent values.
/// Wraps the raw map so live SSE updates can be merged field-by-field.
class LatestSnapshot {
  const LatestSnapshot(this.raw);

  final Map<String, dynamic> raw;

  factory LatestSnapshot.fromJson(Object? v) => LatestSnapshot(_map(v));

  double? _opt(String key) {
    final v = raw[key];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  double? get heartRate => _opt('heart_rate_bpm');
  double? get heartRateMin => _opt('heart_rate_min');
  double? get heartRateMax => _opt('heart_rate_max');
  double? get spo2 => _opt('spo2_percent');
  double? get bodyTemp => _opt('body_temperature_c');
  double? get skinTemp => _opt('skin_temperature_c');
  double? get bpSystolic => _opt('bp_systolic_mmhg');
  double? get bpDiastolic => _opt('bp_diastolic_mmhg');
  double? get steps => _opt('steps');
  double? get distance => _opt('distance_m');
  double? get calories => _opt('calories_kcal');
  double? get battery => _opt('battery_percent');
  double? get rssi => _opt('rssi');
  double? get hrvSdnn => _opt('hrv_sdnn_ms');
  double? get hrvRmssd => _opt('hrv_rmssd_ms');
  double? get hrvPnn50 => _opt('hrv_pnn50');
  double? get hrvMean => _opt('hrv_mean_ms');
  double? get fatigue => _opt('fatigue');
  double? get stress => _opt('stress_level');
  double? get respiration => _opt('respiration_rate');
  double? get bloodSugar => _opt('blood_sugar_mmol');
  bool get charging => _b(raw['charging']);
  String get firmware => _s(raw['firmware']);
  String get mac => _s(raw['mac']);
  String get netType => _s(raw['net_type']);

  bool get isEmpty => raw.isEmpty;

  /// Returns a new snapshot with [updates] merged over the current values.
  LatestSnapshot merge(Map<String, dynamic> updates) {
    final next = Map<String, dynamic>.from(raw);
    updates.forEach((k, v) {
      if (k == 'device_id' || k == 'ts' || k == 'received_at') return;
      if (v != null) next[k] = v;
    });
    return LatestSnapshot(next);
  }
}

class DeviceSummary {
  const DeviceSummary({
    required this.deviceId,
    required this.nickname,
    required this.model,
    required this.status,
    required this.firstSeen,
    required this.lastSeen,
    required this.latest,
  });

  final String deviceId;
  final String nickname;
  final String model;
  final String status;
  final String firstSeen;
  final String lastSeen;
  final LatestSnapshot latest;

  String get displayName => nickname.isNotEmpty ? nickname : deviceId;

  factory DeviceSummary.fromJson(Map<String, dynamic> j) => DeviceSummary(
        deviceId: _s(j['deviceId']),
        nickname: _s(j['nickname']),
        model: _s(j['model']),
        status: _s(j['status'], 'unknown'),
        firstSeen: _s(j['firstSeen']),
        lastSeen: _s(j['lastSeen']),
        latest: LatestSnapshot.fromJson(j['latest']),
      );

  DeviceSummary withLatest(LatestSnapshot next) => DeviceSummary(
        deviceId: deviceId,
        nickname: nickname,
        model: model,
        status: status,
        firstSeen: firstSeen,
        lastSeen: lastSeen,
        latest: next,
      );
}

/// A row from `/v1/api/health-data` (fleet list).
class DeviceRow {
  const DeviceRow({
    required this.id,
    required this.nickname,
    required this.model,
    required this.deviceId,
    required this.status,
    required this.steps,
    required this.heartRate,
    required this.bloodOxygen,
    required this.bodyTemp,
    required this.phone,
    required this.updateTime,
  });

  final String id;
  final String nickname;
  final String model;
  final String deviceId;
  final String status;
  final double steps;
  final double heartRate;
  final double bloodOxygen;
  final double bodyTemp;
  final String phone;
  final String updateTime;

  String get displayName => nickname.isNotEmpty ? nickname : deviceId;
  bool get isOnline => status.toLowerCase() == 'online';

  factory DeviceRow.fromJson(Map<String, dynamic> j) => DeviceRow(
        id: _s(j['id'], _s(j['deviceId'])),
        nickname: _s(j['nickname']),
        model: _s(j['model'], 'IWOWN'),
        deviceId: _s(j['deviceId'], _s(j['id'])),
        status: _s(j['status'], 'unknown'),
        steps: _d(j['steps']),
        heartRate: _d(j['heartRate']),
        bloodOxygen: _d(j['bloodOxygen']),
        bodyTemp: _d(j['bodyTemp']),
        phone: _s(j['phone']),
        updateTime: _s(j['updateTime']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'model': model,
        'deviceId': deviceId,
        'status': status,
        'steps': steps,
        'heartRate': heartRate,
        'bloodOxygen': bloodOxygen,
        'bodyTemp': bodyTemp,
        'phone': phone,
        'updateTime': updateTime,
      };

  DeviceRow copyWith({
    double? steps,
    double? heartRate,
    double? bloodOxygen,
    double? bodyTemp,
    String? status,
    String? updateTime,
  }) =>
      DeviceRow(
        id: id,
        nickname: nickname,
        model: model,
        deviceId: deviceId,
        status: status ?? this.status,
        steps: steps ?? this.steps,
        heartRate: heartRate ?? this.heartRate,
        bloodOxygen: bloodOxygen ?? this.bloodOxygen,
        bodyTemp: bodyTemp ?? this.bodyTemp,
        phone: phone,
        updateTime: updateTime ?? this.updateTime,
      );

  /// Folds a realtime sample push into this row (instant fleet-list updates).
  DeviceRow applyLive(Map<String, dynamic> f) => copyWith(
        steps: f['steps'] is num ? (f['steps'] as num).toDouble() : null,
        heartRate: f['heart_rate_bpm'] is num
            ? (f['heart_rate_bpm'] as num).toDouble()
            : null,
        bloodOxygen: f['spo2_percent'] is num
            ? (f['spo2_percent'] as num).toDouble()
            : null,
        bodyTemp: f['body_temperature_c'] is num
            ? (f['body_temperature_c'] as num).toDouble()
            : null,
      );
}

class DeviceInfo {
  const DeviceInfo({
    required this.deviceId,
    required this.nickname,
    required this.model,
    required this.firmwareVersion,
    required this.phone,
    required this.macAddress,
    required this.networkType,
    required this.networkOperator,
    required this.simIccid,
    required this.battery,
    required this.signal,
    required this.status,
    required this.lastSeen,
  });

  final String deviceId;
  final String nickname;
  final String model;
  final String firmwareVersion;
  final String phone;
  final String macAddress;
  final String networkType;
  final String networkOperator;
  final String simIccid;
  final double battery;
  final double signal;
  final String status;
  final String lastSeen;

  factory DeviceInfo.fromJson(Map<String, dynamic> j) => DeviceInfo(
        deviceId: _s(j['deviceId']),
        nickname: _s(j['nickname']),
        model: _s(j['model']),
        firmwareVersion: _s(j['firmwareVersion']),
        phone: _s(j['phone']),
        macAddress: _s(j['macAddress']),
        networkType: _s(j['networkType']),
        networkOperator: _s(j['networkOperator']),
        simIccid: _s(j['simIccid']),
        battery: _d(j['battery']),
        signal: _d(j['signal']),
        status: _s(j['status'], 'unknown'),
        lastSeen: _s(j['lastSeen']),
      );
}

class Vitals {
  const Vitals({
    required this.heartRate,
    required this.bloodPressure,
    required this.bloodOxygen,
    required this.bodyTemp,
  });

  final MetricSeries heartRate;
  final BloodPressureSeries bloodPressure;
  final MetricSeries bloodOxygen;
  final BodyTempSeries bodyTemp;

  factory Vitals.fromJson(Map<String, dynamic> j) => Vitals(
        heartRate: MetricSeries.fromJson(_map(j['heartrate']), unitFallback: 'bpm'),
        bloodPressure: BloodPressureSeries.fromJson(_map(j['bloodpressure'])),
        bloodOxygen: MetricSeries.fromJson(_map(j['bloodoxygen']), unitFallback: '%'),
        bodyTemp: BodyTempSeries.fromJson(_map(j['bodytemp'])),
      );
}

class Overview {
  const Overview({
    required this.steps,
    required this.heartRate,
    required this.bloodOxygen,
    required this.bodyTemp,
    required this.sleepHours,
    required this.distance,
    required this.calories,
    required this.bpSystolic,
    required this.bpDiastolic,
  });

  final double steps;
  final double heartRate;
  final double bloodOxygen;
  final double bodyTemp;
  final double sleepHours;
  final double distance;
  final double calories;
  final double bpSystolic;
  final double bpDiastolic;

  factory Overview.fromJson(Map<String, dynamic> j) {
    final bp = _map(j['bloodPressure']);
    return Overview(
      steps: _d(j['steps']),
      heartRate: _d(j['heartRate']),
      bloodOxygen: _d(j['bloodOxygen']),
      bodyTemp: _d(j['bodyTemp']),
      sleepHours: _d(j['sleepHours']),
      distance: _d(j['distance']),
      calories: _d(j['calories']),
      bpSystolic: _d(bp['systolic']),
      bpDiastolic: _d(bp['diastolic']),
    );
  }
}

class SleepSummary {
  const SleepSummary({
    required this.date,
    required this.totalMinutes,
    required this.deepMinutes,
    required this.lightMinutes,
    required this.remMinutes,
    required this.awakeTimes,
    required this.sleepHeartRate,
    required this.apneaRisk,
    required this.sleepScore,
    required this.stagesAvailable,
  });

  final String date;
  final int totalMinutes;
  final int deepMinutes;
  final int lightMinutes;
  final int remMinutes;
  final int awakeTimes;
  final double sleepHeartRate;
  final String apneaRisk;
  final double sleepScore;
  final bool stagesAvailable;

  bool get hasData => totalMinutes > 0;
  double get totalHours => totalMinutes / 60.0;

  factory SleepSummary.fromJson(Map<String, dynamic> j) => SleepSummary(
        date: _s(j['date']),
        totalMinutes: _i(j['totalMinutes']),
        deepMinutes: _i(j['deepSleepMinutes']),
        lightMinutes: _i(j['lightSleepMinutes']),
        remMinutes: _i(j['remSleepMinutes']),
        awakeTimes: _i(j['awakeTimes']),
        sleepHeartRate: _d(j['sleepHeartRate']),
        apneaRisk: _s(j['apneaRisk'], 'Unknown'),
        sleepScore: _d(j['sleepScore']),
        stagesAvailable: _b(j['stagesAvailable']),
      );
}

class HeartHealth {
  const HeartHealth({
    required this.date,
    required this.diagnosis,
    required this.afibRisk,
    required this.hrvScore,
    required this.series,
    required this.sdnn,
    required this.rmssd,
    required this.pnn50,
    required this.meanRr,
    required this.fatigue,
  });

  final String date;
  final String diagnosis;
  final String afibRisk;
  final double hrvScore;
  final List<TimeValue> series;
  final double sdnn;
  final double rmssd;
  final double pnn50;
  final double meanRr;
  final double fatigue;

  bool get hasData => hrvScore > 0 || series.isNotEmpty;

  factory HeartHealth.fromJson(Map<String, dynamic> j) => HeartHealth(
        date: _s(j['date']),
        diagnosis: _s(j['diagnosis']),
        afibRisk: _s(j['afibRisk'], 'Unknown'),
        hrvScore: _d(j['hrvScore']),
        series: (j['series'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => TimeValue.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        sdnn: _d(j['sdnn']),
        rmssd: _d(j['rmssd']),
        pnn50: _d(j['pnn50']),
        meanRr: _d(j['meanRr']),
        fatigue: _d(j['fatigue']),
      );
}

class PressureSummary {
  const PressureSummary({
    required this.date,
    required this.series,
    required this.average,
    required this.level,
  });

  final String date;
  final List<TimeValue> series;
  final double average;
  final String level;

  bool get hasData => series.isNotEmpty || average > 0;

  factory PressureSummary.fromJson(Map<String, dynamic> j) => PressureSummary(
        date: _s(j['date']),
        series: (j['series'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => TimeValue.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        average: _d(j['average']),
        level: _s(j['level'], 'Unknown'),
      );
}

class Wellness {
  const Wellness({
    required this.overview,
    required this.sleep,
    required this.heartHealth,
    required this.pressure,
  });

  final Overview overview;
  final SleepSummary sleep;
  final HeartHealth heartHealth;
  final PressureSummary pressure;

  factory Wellness.fromJson(Map<String, dynamic> j) => Wellness(
        overview: Overview.fromJson(_map(j['overview'])),
        sleep: SleepSummary.fromJson(_map(j['sleep'])),
        heartHealth: HeartHealth.fromJson(_map(j['hearthealth'])),
        pressure: PressureSummary.fromJson(_map(j['pressure'])),
      );
}

class ActivityBundle {
  const ActivityBundle({required this.series, required this.total, required this.unit});

  final List<TimeValue> series;
  final double total;
  final String unit;

  factory ActivityBundle.fromJson(Map<String, dynamic> j, String unit) => ActivityBundle(
        series: (j['series'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => TimeValue.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        total: _d(j['total']),
        unit: _s(j['unit'], unit),
      );
}

class Activity {
  const Activity({
    required this.date,
    required this.steps,
    required this.distance,
    required this.calories,
  });

  final String date;
  final ActivityBundle steps;
  final ActivityBundle distance;
  final ActivityBundle calories;

  factory Activity.fromJson(Map<String, dynamic> j) => Activity(
        date: _s(j['date']),
        steps: ActivityBundle.fromJson(_map(j['steps']), ''),
        distance: ActivityBundle.fromJson(_map(j['distance']), 'm'),
        calories: ActivityBundle.fromJson(_map(j['calories']), 'kcal'),
      );
}

class AlarmRow {
  const AlarmRow({
    required this.id,
    required this.nickname,
    required this.deviceId,
    required this.type,
    required this.time,
    required this.location,
    required this.content,
  });

  final String id;
  final String nickname;
  final String deviceId;
  final String type;
  final String time;
  final String location;
  final String content;

  bool get isSos => RegExp('sos', caseSensitive: false).hasMatch(type);
  bool get isFall => RegExp('fall', caseSensitive: false).hasMatch(type);
  bool get isSedentary => RegExp('sedentary', caseSensitive: false).hasMatch(type);

  /// `"lat,lng"` parsed into a pair, or null when no coordinate is attached.
  (double, double)? get latLng {
    if (location.isEmpty || !location.contains(',')) return null;
    final parts = location.split(',');
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts.length > 1 ? parts[1].trim() : '');
    if (lat == null || lng == null) return null;
    return (lat, lng);
  }

  factory AlarmRow.fromJson(Map<String, dynamic> j) => AlarmRow(
        id: _s(j['id']),
        nickname: _s(j['nickname']),
        deviceId: _s(j['deviceId']),
        type: _s(j['type']),
        time: _s(j['time']),
        location: _s(j['location']),
        content: _s(j['content']),
      );
}

class CallLog {
  const CallLog({
    required this.status,
    required this.number,
    required this.startTime,
    required this.endTime,
  });

  final int status;
  final String number;
  final String startTime;
  final String endTime;

  factory CallLog.fromJson(Map<String, dynamic> j) => CallLog(
        status: _i(j['status']),
        number: _s(j['call_number']),
        startTime: _s(j['start_time']),
        endTime: _s(j['end_time']),
      );
}

class SosData {
  const SosData({
    required this.sosEvents,
    required this.fallAlarms,
    required this.sedentaryAlarms,
    required this.callLogs,
  });

  final List<AlarmRow> sosEvents;
  final List<AlarmRow> fallAlarms;
  final List<AlarmRow> sedentaryAlarms;
  final List<CallLog> callLogs;

  bool get isEmpty =>
      sosEvents.isEmpty &&
      fallAlarms.isEmpty &&
      sedentaryAlarms.isEmpty &&
      callLogs.isEmpty;

  factory SosData.fromJson(Map<String, dynamic> j) => SosData(
        sosEvents: _mapList(j['sosEvents']).map(AlarmRow.fromJson).toList(),
        fallAlarms: _mapList(j['fallAlarms']).map(AlarmRow.fromJson).toList(),
        sedentaryAlarms:
            _mapList(j['sedentaryAlarms']).map(AlarmRow.fromJson).toList(),
        callLogs: _mapList(j['callLogs']).map(CallLog.fromJson).toList(),
      );
}

class TrackPoint {
  const TrackPoint({
    required this.lat,
    required this.lng,
    required this.time,
    required this.locateType,
  });

  final double lat;
  final double lng;
  final String time;
  final String locateType;

  factory TrackPoint.fromJson(Map<String, dynamic> j) => TrackPoint(
        lat: _d(j['lat']),
        lng: _d(j['lng']),
        time: _s(j['time']),
        locateType: _s(j['locateType']),
      );
}

class LocationTrack {
  const LocationTrack({
    required this.date,
    required this.tracks,
    required this.lastLat,
    required this.lastLng,
  });

  final String date;
  final List<TrackPoint> tracks;
  final double? lastLat;
  final double? lastLng;

  bool get hasData => tracks.isNotEmpty || (lastLat != null && lastLng != null);

  factory LocationTrack.fromJson(Map<String, dynamic> j) {
    final last = j['lastLocation'];
    double? lat;
    double? lng;
    if (last is Map) {
      lat = _d(last['lat']);
      lng = _d(last['lng']);
    }
    return LocationTrack(
      date: _s(j['date']),
      tracks: _mapList(j['tracks']).map(TrackPoint.fromJson).toList(),
      lastLat: lat,
      lastLng: lng,
    );
  }
}

class EcgRecord {
  const EcgRecord({required this.time, required this.wave});

  final String time;
  final List<double> wave;

  factory EcgRecord.fromJson(Map<String, dynamic> j) => EcgRecord(
        time: _s(j['time']),
        wave: (j['wave'] as List? ?? const []).map((e) => _d(e)).toList(),
      );
}

class EcgData {
  const EcgData({required this.date, required this.records, required this.aiResult});

  final String date;
  final List<EcgRecord> records;
  final String aiResult;

  bool get hasData => records.isNotEmpty;

  factory EcgData.fromJson(Map<String, dynamic> j) => EcgData(
        date: _s(j['date']),
        records: _mapList(j['records']).map(EcgRecord.fromJson).toList(),
        aiResult: _s(j['aiResult']),
      );
}

class FleetStats {
  const FleetStats({
    required this.totalDevices,
    required this.onlineDevices,
    required this.offlineDevices,
    required this.totalAlarms,
  });

  final int totalDevices;
  final int onlineDevices;
  final int offlineDevices;
  final int totalAlarms;

  factory FleetStats.fromJson(Map<String, dynamic> j) => FleetStats(
        totalDevices: _i(j['totalDevices']),
        onlineDevices: _i(j['onlineDevices']),
        offlineDevices: _i(j['offlineDevices']),
        totalAlarms: _i(j['totalAlarms']),
      );

  static const empty =
      FleetStats(totalDevices: 0, onlineDevices: 0, offlineDevices: 0, totalAlarms: 0);
}

class ApiHealth {
  const ApiHealth({
    required this.status,
    required this.mongo,
    required this.realtime,
    required this.sseClients,
  });

  final String status;
  final String mongo;
  final String realtime;
  final int sseClients;

  bool get ok => status == 'ok';
  bool get realtimeConnected => realtime == 'connected';

  factory ApiHealth.fromJson(Map<String, dynamic> j) => ApiHealth(
        status: _s(j['status']),
        mongo: _s(j['mongo']),
        realtime: _s(j['realtime']),
        sseClients: _i(j['sseClients']),
      );
}

/// A decoded realtime push from the SSE `update` event — the raw sample doc
/// the ingestion service published for a device.
class LiveUpdate {
  const LiveUpdate({required this.deviceId, required this.fields});

  final String deviceId;
  final Map<String, dynamic> fields;

  factory LiveUpdate.fromJson(Map<String, dynamic> j) =>
      LiveUpdate(deviceId: _s(j['device_id']), fields: j);
}
