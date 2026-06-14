import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/device_models.dart';

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

  Future<void> showAlarms(List<AlarmRow> alarms) async {
    final important = alarms.where((alarm) => alarm.isSos || alarm.isFall);

    for (final alarm in important) {
      final key = alarm.id.isEmpty ? '${alarm.deviceId}-${alarm.time}' : alarm.id;
      if (_shownAlertIds.contains(key)) {
        continue;
      }

      _shownAlertIds.add(key);
      try {
        await _plugin.show(
          id: key.hashCode.abs(),
          title: alarm.isSos ? 'SOS alert' : 'Fall alert',
          body: alarm.content.isEmpty
              ? '${alarm.deviceId} reported ${alarm.type}'
              : alarm.content,
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
