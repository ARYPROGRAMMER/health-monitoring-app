import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/health_models.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Set<String> _shownAlertIds = <String>{};

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showHealthAlerts(List<HealthAlertModel> alerts) async {
    final activeAlerts = alerts
        .where((alert) => alert.isActive && alert.isNotificationWorthy)
        .toList();

    for (final alert in activeAlerts) {
      if (_shownAlertIds.contains(alert.id)) {
        continue;
      }

      _shownAlertIds.add(alert.id);
      try {
        await _plugin.show(
          id: alert.id.hashCode.abs(),
          title: alert.title,
          body: alert.message,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'stealthera_health_alerts',
              'Health alerts',
              channelDescription: 'Health threshold and wellness alerts',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      } catch (_) {}
    }
  }
}
