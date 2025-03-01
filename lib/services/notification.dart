import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:school_day/data/timetable.dart';
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<String?> getDeviceToken() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? token = await messaging.getToken();

  return token;
}

void initializeNotifications() async {
  var initializationSettingsAndroid =
      const AndroidInitializationSettings('app_icon');
  var initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> scheduleNotification(Timetable lesson) async {
  final currentTime = DateTime.now();
  final targetTime = DateTime(
    currentTime.year,
    currentTime.month,
    currentTime.day,
    lesson.startTime.hour,
    lesson.startTime.minute,
  );

  final difference = targetTime.isAfter(currentTime)
      ? targetTime.difference(currentTime)
      : const Duration(seconds: 0);

  if (difference.inSeconds > 0) {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'แจ้งเตือนเวลาเข้าเรียน',
      'ถึงเวลาเรียน ${lesson.title} กับ${lesson.professor} ที่${lesson.location}แล้วนะ - ${lesson.startTime.toString()} ><',
      tz.TZDateTime.from(targetTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'class_reminder_channel',
          'แจ้งเตือนเวลาเข้าเรียน',
          channelDescription: 'แจ้งเตือนเมื่อถึงเวลาเข้าเรียน',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'app_icon',
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
