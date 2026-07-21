import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/reminder.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    await _requestPermissions();
    _initialized = true;
  }

  static Future<void> scheduleReminder(Reminder reminder) async {
    await initialize();
    final id = reminder.id;
    if (id == null) return;

    final date = DateTime.tryParse(reminder.scheduledAt);
    if (date == null || date.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      id,
      reminder.title,
      _notificationBody(reminder),
      tz.TZDateTime.from(date, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'business_reminders',
          'Recordatorios',
          channelDescription:
              'Alertas para cobrar, despachar y dar seguimiento',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'reminder:$id',
    );
  }

  static Future<void> cancelReminder(int id) async {
    await initialize();
    await _notifications.cancel(id);
  }

  static Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static String _notificationBody(Reminder reminder) {
    final parts = <String>[
      if (reminder.customerName.isNotEmpty) reminder.customerName,
      if (reminder.ticketLabel.isNotEmpty) reminder.ticketLabel,
      if (reminder.notes.isNotEmpty) reminder.notes,
    ];
    return parts.isEmpty
        ? 'Tienes un recordatorio pendiente'
        : parts.join(' · ');
  }
}
