class CacheKeys {
  // Appearance + onboarding
  static const themeMode = 'themeMode';
  static const accent = 'accent';
  static const onboarded = 'onboarded';
  static const notificationsEnabled = 'notificationsEnabled';

  // Device session + offline snapshots
  static const activeDevice = 'activeDevice';
  static const devices = 'devicesCache';
  static String deviceSummary(String id) => 'summary_$id';
}
