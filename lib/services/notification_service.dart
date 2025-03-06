import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:school_day/data/timetable.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    const initSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    await notificationsPlugin.initialize(initSettings);
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'weekly_channel_id',
        'การแจ้งเตือนการเข้าเรียน',
        channelDescription: 'แจ้งเตือนให้คุณรู้ว่าถึงเวลาเรียนตามในตารางแล้ว',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        enableVibration: true,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> scheduleWeeklyTimetableNotifications(
    Map<int, List<Timetable>> timetableList,
  ) async {
    if (kIsWeb) return;

    await notificationsPlugin.cancelAll();

    for (var day = 0; day < 7; day++) {
      for (var classData in timetableList[day] ?? []) {
        await scheduleNotification(timetable: classData, dateIndex: day);
      }
    }
  }

  Future<void> scheduleNotification({
    int id = 1,
    required Timetable timetable,
    required int dateIndex,
  }) async {
    if (!timetable.isNotify ||
        await Permission.notification.isDenied ||
        await Permission.scheduleExactAlarm.isDenied) {
      return;
    }

    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timetable.startTime.hour,
      timetable.startTime.minute,
    );

    scheduledDate = scheduledDate.subtract(
      Duration(
        hours: timetable.notifyTime.hour,
        minutes: timetable.notifyTime.minute,
      ),
    );

    int daysUntilNext = ((dateIndex + 1) - now.weekday) % 7;

    if (now.isAfter(scheduledDate)) {
      daysUntilNext += 7;
    }

    scheduledDate = scheduledDate.add(Duration(days: daysUntilNext));

    await notificationsPlugin.zonedSchedule(
      timetable.id.hashCode,
      'ถึงเวลาเรียน 📚',
      'ถึงเวลาเรียนวิชา ${timetable.title} แล้วจ้า ${timetable.startTime} น. - ${timetable.endTime} น.',
      scheduledDate,
      notificationDetails(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
  }
}
