import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String channelId = 'bandunghub_travel_reminders';
  static const String channelName = 'Pengingat Wisata BandungHub';
  static const String channelDescription =
      'Notifikasi pengingat jadwal kunjungan destinasi dan itinerary liburan BandungHub';

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error (safe fallback): $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final androidPlatform = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlatform != null) {
        final granted = await androidPlatform.requestNotificationsPermission();
        try {
          await androidPlatform.requestExactAlarmsPermission();
        } catch (_) {}
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('NotificationService requestPermissions error: $e');
      return true;
    }
  }

  NotificationDetails _buildNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );
    return const NotificationDetails(android: androidDetails);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _buildNotificationDetails(),
        payload: payload,
      );
    } catch (e) {
      debugPrint('NotificationService showNotification error: $e');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);
      if (tzScheduled.isBefore(now)) {
        tzScheduled = now.add(const Duration(seconds: 1));
      }

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduled,
        notificationDetails: _buildNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      debugPrint('NotificationService scheduleNotification error: $e');
      // Fallback for devices restricting exact alarms
      try {
        final now = tz.TZDateTime.now(tz.local);
        var tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);
        if (tzScheduled.isBefore(now)) {
          tzScheduled = now.add(const Duration(seconds: 1));
        }
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzScheduled,
          notificationDetails: _buildNotificationDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );
      } catch (fallbackError) {
        debugPrint('NotificationService fallback schedule error: $fallbackError');
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('NotificationService cancelNotification error: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService cancelAll error: $e');
    }
  }
}
