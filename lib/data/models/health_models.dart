class HealthReadingModel {
  const HealthReadingModel({
    required this.type,
    required this.value,
    required this.unit,
    required this.recordedAt,
  });

  final String type;
  final double value;
  final String unit;
  final DateTime recordedAt;

  factory HealthReadingModel.fromJson(Map<String, dynamic> json) {
    return HealthReadingModel(
      type: json['type'] as String? ?? '',
      value: _doubleFromValue(json['value']),
      unit: json['unit'] as String? ?? '',
      recordedAt: _dateFromValue(json['recordedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
      'unit': unit,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }
}

class TrendPointModel {
  const TrendPointModel({
    required this.value,
    required this.unit,
    required this.recordedAt,
  });

  final double value;
  final String unit;
  final DateTime recordedAt;

  factory TrendPointModel.fromJson(Map<String, dynamic> json) {
    return TrendPointModel(
      value: _doubleFromValue(json['value']),
      unit: json['unit'] as String? ?? '',
      recordedAt: _dateFromValue(json['recordedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'unit': unit,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }
}

class HealthAlertModel {
  const HealthAlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.metricValue,
    required this.thresholdValue,
    required this.status,
    required this.createdAt,
    required this.resolvedAt,
  });

  final String id;
  final String type;
  final String severity;
  final String title;
  final String message;
  final double metricValue;
  final double thresholdValue;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  bool get isActive => status == 'active';
  bool get isCritical => severity == 'critical';
  bool get isNotificationWorthy => isCritical || severity == 'warning';

  factory HealthAlertModel.fromJson(Map<String, dynamic> json) {
    return HealthAlertModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      severity: json['severity'] as String? ?? 'info',
      title: json['title'] as String? ?? 'Health alert',
      message: json['message'] as String? ?? '',
      metricValue: _doubleFromValue(json['metricValue']),
      thresholdValue: _doubleFromValue(json['thresholdValue']),
      status: json['status'] as String? ?? 'active',
      createdAt: _dateFromValue(json['createdAt']),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : _dateFromValue(json['resolvedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'severity': severity,
      'title': title,
      'message': message,
      'metricValue': metricValue,
      'thresholdValue': thresholdValue,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }
}

class HealthSettingsModel {
  const HealthSettingsModel({
    required this.heartRateMin,
    required this.heartRateMax,
    required this.spo2Min,
    required this.dailyStepsGoal,
    required this.sleepTargetHours,
    required this.notificationsEnabled,
    required this.darkMode,
  });

  final int heartRateMin;
  final int heartRateMax;
  final double spo2Min;
  final int dailyStepsGoal;
  final double sleepTargetHours;
  final bool notificationsEnabled;
  final bool darkMode;

  static const defaults = HealthSettingsModel(
    heartRateMin: 50,
    heartRateMax: 120,
    spo2Min: 94,
    dailyStepsGoal: 8000,
    sleepTargetHours: 7.5,
    notificationsEnabled: true,
    darkMode: false,
  );

  factory HealthSettingsModel.fromJson(Map<String, dynamic> json) {
    return HealthSettingsModel(
      heartRateMin: _intFromValue(json['heartRateMin'], defaults.heartRateMin),
      heartRateMax: _intFromValue(json['heartRateMax'], defaults.heartRateMax),
      spo2Min: _doubleFromValue(json['spo2Min'], defaults.spo2Min),
      dailyStepsGoal: _intFromValue(
        json['dailyStepsGoal'],
        defaults.dailyStepsGoal,
      ),
      sleepTargetHours: _doubleFromValue(
        json['sleepTargetHours'],
        defaults.sleepTargetHours,
      ),
      notificationsEnabled:
          json['notificationsEnabled'] as bool? ??
          defaults.notificationsEnabled,
      darkMode: json['darkMode'] as bool? ?? defaults.darkMode,
    );
  }

  HealthSettingsModel copyWith({
    int? heartRateMin,
    int? heartRateMax,
    double? spo2Min,
    int? dailyStepsGoal,
    double? sleepTargetHours,
    bool? notificationsEnabled,
    bool? darkMode,
  }) {
    return HealthSettingsModel(
      heartRateMin: heartRateMin ?? this.heartRateMin,
      heartRateMax: heartRateMax ?? this.heartRateMax,
      spo2Min: spo2Min ?? this.spo2Min,
      dailyStepsGoal: dailyStepsGoal ?? this.dailyStepsGoal,
      sleepTargetHours: sleepTargetHours ?? this.sleepTargetHours,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'heartRateMin': heartRateMin,
      'heartRateMax': heartRateMax,
      'spo2Min': spo2Min,
      'dailyStepsGoal': dailyStepsGoal,
      'sleepTargetHours': sleepTargetHours,
      'notificationsEnabled': notificationsEnabled,
      'darkMode': darkMode,
    };
  }
}

class HealthInsightModel {
  const HealthInsightModel({
    required this.id,
    required this.title,
    required this.message,
    required this.tone,
  });

  final String id;
  final String title;
  final String message;
  final String tone;

  factory HealthInsightModel.fromJson(Map<String, dynamic> json) {
    return HealthInsightModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Insight',
      message: json['message'] as String? ?? '',
      tone: json['tone'] as String? ?? 'positive',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'message': message, 'tone': tone};
  }
}

class DashboardSummaryModel {
  const DashboardSummaryModel({
    required this.settings,
    required this.heartRate,
    required this.spo2,
    required this.sleep,
    required this.activity,
    required this.heartRateTrend,
    required this.spo2Trend,
    required this.sleepTrend,
    required this.activityTrend,
    required this.alerts,
    required this.activeAlerts,
    required this.insights,
    required this.generatedAt,
    this.isOffline = false,
    this.errorMessage,
  });

  final HealthSettingsModel settings;
  final HealthReadingModel? heartRate;
  final HealthReadingModel? spo2;
  final HealthReadingModel? sleep;
  final HealthReadingModel? activity;
  final List<TrendPointModel> heartRateTrend;
  final List<TrendPointModel> spo2Trend;
  final List<TrendPointModel> sleepTrend;
  final List<TrendPointModel> activityTrend;
  final List<HealthAlertModel> alerts;
  final List<HealthAlertModel> activeAlerts;
  final List<HealthInsightModel> insights;
  final DateTime generatedAt;
  final bool isOffline;
  final String? errorMessage;

  bool get hasVitals =>
      heartRate != null || spo2 != null || sleep != null || activity != null;

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final latestVitals = Map<String, dynamic>.from(
      json['latestVitals'] as Map? ?? {},
    );
    final trends = Map<String, dynamic>.from(json['trends'] as Map? ?? {});
    final alerts = _alertList(json['alerts']);
    final activeAlerts = _alertList(json['activeAlerts']);

    return DashboardSummaryModel(
      settings: HealthSettingsModel.fromJson(
        Map<String, dynamic>.from(json['settings'] as Map? ?? {}),
      ),
      heartRate: _readingOrNull(latestVitals['heartRate']),
      spo2: _readingOrNull(latestVitals['spo2']),
      sleep: _readingOrNull(json['sleep']),
      activity: _readingOrNull(json['activity']),
      heartRateTrend: _trendList(trends['heartRate']),
      spo2Trend: _trendList(trends['spo2']),
      sleepTrend: _trendList(trends['sleep']),
      activityTrend: _trendList(trends['activity']),
      alerts: alerts,
      activeAlerts: activeAlerts.isEmpty
          ? alerts.where((alert) => alert.isActive).toList()
          : activeAlerts,
      insights: _insightList(json['insights']),
      generatedAt: _dateFromValue(json['generatedAt']),
      isOffline: json['isOffline'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  DashboardSummaryModel copyWith({
    HealthSettingsModel? settings,
    List<HealthAlertModel>? alerts,
    List<HealthAlertModel>? activeAlerts,
    bool? isOffline,
    String? errorMessage,
  }) {
    return DashboardSummaryModel(
      settings: settings ?? this.settings,
      heartRate: heartRate,
      spo2: spo2,
      sleep: sleep,
      activity: activity,
      heartRateTrend: heartRateTrend,
      spo2Trend: spo2Trend,
      sleepTrend: sleepTrend,
      activityTrend: activityTrend,
      alerts: alerts ?? this.alerts,
      activeAlerts: activeAlerts ?? this.activeAlerts,
      insights: insights,
      generatedAt: generatedAt,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'settings': settings.toJson(),
      'latestVitals': {
        'heartRate': heartRate?.toJson(),
        'spo2': spo2?.toJson(),
      },
      'sleep': sleep?.toJson(),
      'activity': activity?.toJson(),
      'trends': {
        'heartRate': heartRateTrend.map((point) => point.toJson()).toList(),
        'spo2': spo2Trend.map((point) => point.toJson()).toList(),
        'sleep': sleepTrend.map((point) => point.toJson()).toList(),
        'activity': activityTrend.map((point) => point.toJson()).toList(),
      },
      'alerts': alerts.map((alert) => alert.toJson()).toList(),
      'activeAlerts': activeAlerts.map((alert) => alert.toJson()).toList(),
      'insights': insights.map((insight) => insight.toJson()).toList(),
      'generatedAt': generatedAt.toIso8601String(),
      'isOffline': isOffline,
      'errorMessage': errorMessage,
    };
  }

  static HealthReadingModel? _readingOrNull(Object? value) {
    if (value is Map) {
      return HealthReadingModel.fromJson(Map<String, dynamic>.from(value));
    }

    return null;
  }

  static List<TrendPointModel> _trendList(Object? value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map(
            (item) => TrendPointModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    return [];
  }

  static List<HealthAlertModel> _alertList(Object? value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map(
            (item) =>
                HealthAlertModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    return [];
  }

  static List<HealthInsightModel> _insightList(Object? value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map(
            (item) =>
                HealthInsightModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    return [];
  }
}

double _doubleFromValue(Object? value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }

  return fallback;
}

int _intFromValue(Object? value, int fallback) {
  if (value is num) {
    return value.round();
  }

  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }

  return fallback;
}

DateTime _dateFromValue(Object? value) {
  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value)?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  if (value is Map) {
    final seconds = value['_seconds'] ?? value['seconds'];
    final nanoseconds = value['_nanoseconds'] ?? value['nanoseconds'] ?? 0;

    if (seconds is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        seconds.round() * 1000 +
            (nanoseconds is num ? nanoseconds.round() ~/ 1000000 : 0),
      );
    }
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}
