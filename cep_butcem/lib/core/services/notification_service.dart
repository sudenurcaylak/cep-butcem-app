import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const androidInitializationSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const darwinInitializationSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
    );

    await _plugin.initialize(initializationSettings);

    _isInitialized = true;
    debugLog('Notification service initialized. timezone=Europe/Istanbul');
  }

  Future<void> requestPermissions() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImplementation?.requestNotificationsPermission();

    final iosImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'cep_butcem_channel',
      'Cep Bütçem Bildirimleri',
      channelDescription: 'Hatırlatıcı ve abonelik bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(id, title, body, details);
  }

  Future<void> scheduleReminderNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    await initialize();

    final now = DateTime.now();

    if (!scheduledAt.isAfter(now)) {
      throw Exception('Hatırlatıcı zamanı şu andan ileri bir saat olmalı.');
    }

    const androidDetails = AndroidNotificationDetails(
      'cep_butcem_channel',
      'Cep Bütçem Bildirimleri',
      channelDescription: 'Hatırlatıcı ve abonelik bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledAt = tz.TZDateTime.from(scheduledAt, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledAt,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'reminder_$id',
    );

    debugLog(
      'Reminder scheduled. id=$id, scheduledAt=${tzScheduledAt.toIso8601String()}',
    );
  }

  Future<void> cancelNotification(int id) async {
    await initialize();
    await _plugin.cancel(id);
    debugLog('Notification cancelled. id=$id');
  }

  Future<void> cancelAllNotifications() async {
    await initialize();
    await _plugin.cancelAll();
    debugLog('All notifications cancelled');
  }

  Future<List<PendingNotificationRequest>> pendingRequests() async {
    await initialize();
    return _plugin.pendingNotificationRequests();
  }

  void debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[NotificationService] $message');
    }
  }
}
