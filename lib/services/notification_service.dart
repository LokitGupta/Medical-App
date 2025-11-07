import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Skip initialization on web (plugin not supported)
    if (kIsWeb) return;
    // Initialize timezone
    tz_data.initializeTimeZones();

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    // Firebase Messaging is disabled for web build compatibility.
  }

  static Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return; // Not supported on web
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medical_app_channel',
      'Medical App Notifications',
      channelDescription: 'Notifications from Medical App',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  static Future<void> scheduleMedicationReminder({
    required int id,
    required String medicineName,
    required String dosage,
    required DateTime scheduledTime,
  }) async {
    if (kIsWeb) return; // Not supported on web
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'medication_reminder_channel',
      'Medication Reminders',
      channelDescription: 'Reminders for taking medications',
      importance: Importance.high,
      priority: Priority.high,
    );
    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id,
      'Medication Reminder',
      'Time to take $medicineName - $dosage',
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelMedicationReminder(int id) async {
    if (kIsWeb) return; // Not supported on web
    await _localNotifications.cancel(id);
  }

  static Future<String?> getFirebaseToken() async {
    // FCM disabled; return null token.
    return null;
  }
}