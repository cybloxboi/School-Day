import 'dart:io';

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

    const initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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

    if (Platform.isIOS) {
      final iosPlugin =
          notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
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
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> scheduleWeeklyTimetableNotifications(
    List<Timetable> timetableList,
    int dateIndex,
  ) async {
    if (kIsWeb) return;

    await notificationsPlugin.cancelAll();

    for (var classData in timetableList) {
      await scheduleNotification(timetable: classData, dateIndex: dateIndex);
    }
  }

  Future<void> scheduleNotification({
    int id = 1,
    required Timetable timetable,
    required int dateIndex,
  }) async {
    final isNotificationDenied =
        Platform.isAndroid ? await Permission.notification.isDenied : false;

    final isExactAlarmDenied = Platform.isAndroid
        ? await Permission.scheduleExactAlarm.isDenied
        : false;

    if (!timetable.isNotify || isNotificationDenied || isExactAlarmDenied) {
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
      'ถึงเวลาเรียนวิชา ${timetable.title} ${timetable.startTime} น. - ${timetable.endTime} น.',
      scheduledDate,
      notificationDetails(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
  }
}

void requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}
