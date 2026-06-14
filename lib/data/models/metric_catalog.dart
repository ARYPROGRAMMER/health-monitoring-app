import 'package:flutter/material.dart';

/// How a metric's series is fetched from the API.
enum MetricSource { generic, bodyTemp, bloodPressure }

/// A single monitorable metric: how to fetch it, label it, and colour it.
/// The metric-detail screen is fully data-driven from these specs.
class MetricSpec {
  const MetricSpec({
    required this.key,
    required this.title,
    required this.shortTitle,
    required this.unit,
    required this.icon,
    required this.color,
    this.decimals = 0,
    this.normalLow,
    this.normalHigh,
    this.source = MetricSource.generic,
    this.allowZero = false,
  });

  /// API metric key (matches `/v1/api/metrics`).
  final String key;
  final String title;
  final String shortTitle;
  final String unit;
  final IconData icon;
  final Color color;
  final int decimals;
  final double? normalLow;
  final double? normalHigh;
  final MetricSource source;

  /// When true, a 0 value is meaningful (steps, stress) and not "no data".
  final bool allowZero;

  /// Whether [value] falls outside the metric's normal band.
  bool isOutOfRange(double value) {
    if (normalLow != null && value < normalLow!) return true;
    if (normalHigh != null && value > normalHigh!) return true;
    return false;
  }

  /// The raw MongoDB field this metric maps to — used to pull a live value out
  /// of a realtime sample push for the hero number.
  String get field => switch (key) {
        'heartRate' => 'heart_rate_bpm',
        'bloodOxygen' => 'spo2_percent',
        'bodyTemp' => 'body_temperature_c',
        'bloodPressure' => 'bp_systolic_mmhg',
        'steps' => 'steps',
        'distance' => 'distance_m',
        'calories' => 'calories_kcal',
        'hrv' => 'hrv_sdnn_ms',
        'stress' => 'stress_level',
        'respiration' => 'respiration_rate',
        'bloodSugar' => 'blood_sugar_mmol',
        'bloodKetone' => 'blood_ketone',
        'uricAcid' => 'uric_acid_umol',
        'bloodPotassium' => 'blood_potassium_mmol',
        'bmi' => 'bmi',
        'bodyFat' => 'body_fat_percent',
        'battery' => 'battery_percent',
        'signal' => 'rssi',
        _ => key,
      };

  static const _hr = Color(0xFFFF5A6E);
  static const _spo2 = Color(0xFF4FC3F7);
  static const _temp = Color(0xFFFFA726);
  static const _bp = Color(0xFFEC407A);
  static const _steps = Color(0xFF34D17A);
  static const _dist = Color(0xFF26C6DA);
  static const _cal = Color(0xFFFF7043);
  static const _hrv = Color(0xFFAB7DF6);
  static const _stress = Color(0xFFFFCA28);
  static const _resp = Color(0xFF42A5F5);
  static const _sugar = Color(0xFF7E57C2);
  static const _ket = Color(0xFF8D6E63);
  static const _uric = Color(0xFF66BB6A);
  static const _pot = Color(0xFF26A69A);
  static const _bmi = Color(0xFF5C9DF5);
  static const _fat = Color(0xFFEF9A9A);
  static const _batt = Color(0xFF9CCC65);
  static const _sig = Color(0xFF90A4AE);

  static const heartRate = MetricSpec(
    key: 'heartRate',
    title: 'Heart Rate',
    shortTitle: 'Heart',
    unit: 'bpm',
    icon: Icons.favorite_rounded,
    color: _hr,
    normalLow: 50,
    normalHigh: 120,
  );

  static const bloodOxygen = MetricSpec(
    key: 'bloodOxygen',
    title: 'Blood Oxygen',
    shortTitle: 'SpO₂',
    unit: '%',
    icon: Icons.air_rounded,
    color: _spo2,
    normalLow: 95,
  );

  static const bodyTemp = MetricSpec(
    key: 'bodyTemp',
    title: 'Body Temperature',
    shortTitle: 'Body Temp',
    unit: '°C',
    icon: Icons.thermostat_rounded,
    color: _temp,
    decimals: 1,
    normalLow: 35.5,
    normalHigh: 37.5,
    source: MetricSource.bodyTemp,
  );

  static const bloodPressure = MetricSpec(
    key: 'bloodPressure',
    title: 'Blood Pressure',
    shortTitle: 'BP',
    unit: 'mmHg',
    icon: Icons.monitor_heart_rounded,
    color: _bp,
    source: MetricSource.bloodPressure,
  );

  static const steps = MetricSpec(
    key: 'steps',
    title: 'Steps',
    shortTitle: 'Steps',
    unit: 'steps',
    icon: Icons.directions_walk_rounded,
    color: _steps,
    allowZero: true,
  );

  static const distance = MetricSpec(
    key: 'distance',
    title: 'Distance',
    shortTitle: 'Distance',
    unit: 'm',
    icon: Icons.route_rounded,
    color: _dist,
    decimals: 1,
    allowZero: true,
  );

  static const calories = MetricSpec(
    key: 'calories',
    title: 'Calories',
    shortTitle: 'Calories',
    unit: 'kcal',
    icon: Icons.local_fire_department_rounded,
    color: _cal,
    decimals: 1,
    allowZero: true,
  );

  static const hrv = MetricSpec(
    key: 'hrv',
    title: 'Heart Rate Variability',
    shortTitle: 'HRV',
    unit: 'ms',
    icon: Icons.ssid_chart_rounded,
    color: _hrv,
  );

  static const stress = MetricSpec(
    key: 'stress',
    title: 'Stress',
    shortTitle: 'Stress',
    unit: '',
    icon: Icons.self_improvement_rounded,
    color: _stress,
    allowZero: true,
  );

  static const respiration = MetricSpec(
    key: 'respiration',
    title: 'Respiration',
    shortTitle: 'Respiration',
    unit: 'rpm',
    icon: Icons.waves_rounded,
    color: _resp,
  );

  static const bloodSugar = MetricSpec(
    key: 'bloodSugar',
    title: 'Blood Glucose',
    shortTitle: 'Glucose',
    unit: 'mmol/L',
    icon: Icons.water_drop_rounded,
    color: _sugar,
    decimals: 1,
  );

  static const bloodKetone = MetricSpec(
    key: 'bloodKetone',
    title: 'Blood Ketone',
    shortTitle: 'Ketone',
    unit: 'mmol/L',
    icon: Icons.science_rounded,
    color: _ket,
    decimals: 2,
  );

  static const uricAcid = MetricSpec(
    key: 'uricAcid',
    title: 'Uric Acid',
    shortTitle: 'Uric Acid',
    unit: 'µmol/L',
    icon: Icons.bloodtype_rounded,
    color: _uric,
  );

  static const bloodPotassium = MetricSpec(
    key: 'bloodPotassium',
    title: 'Blood Potassium',
    shortTitle: 'Potassium',
    unit: 'mmol/L',
    icon: Icons.bolt_rounded,
    color: _pot,
    decimals: 1,
  );

  static const bmi = MetricSpec(
    key: 'bmi',
    title: 'Body Mass Index',
    shortTitle: 'BMI',
    unit: '',
    icon: Icons.accessibility_new_rounded,
    color: _bmi,
    decimals: 1,
  );

  static const bodyFat = MetricSpec(
    key: 'bodyFat',
    title: 'Body Fat',
    shortTitle: 'Body Fat',
    unit: '%',
    icon: Icons.pie_chart_rounded,
    color: _fat,
    decimals: 1,
  );

  static const battery = MetricSpec(
    key: 'battery',
    title: 'Battery',
    shortTitle: 'Battery',
    unit: '%',
    icon: Icons.battery_charging_full_rounded,
    color: _batt,
    allowZero: true,
  );

  static const signal = MetricSpec(
    key: 'signal',
    title: 'Signal (RSSI)',
    shortTitle: 'Signal',
    unit: 'dBm',
    icon: Icons.signal_cellular_alt_rounded,
    color: _sig,
  );

  static const vitals = [heartRate, bloodOxygen, bodyTemp, bloodPressure, respiration];
  static const activity = [steps, distance, calories];
  static const wellness = [hrv, stress];
  static const metabolic = [bloodSugar, bloodKetone, uricAcid, bloodPotassium];
  static const body = [bmi, bodyFat];
  static const device = [battery, signal];

  static const all = [
    ...vitals,
    ...activity,
    ...wellness,
    ...metabolic,
    ...body,
    ...device,
  ];

  static MetricSpec? byKey(String key) {
    for (final m in all) {
      if (m.key == key) return m;
    }
    return null;
  }
}
