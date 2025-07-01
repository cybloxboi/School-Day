import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const String _classChannelId = 'notify_class_time_channel';
const String _taskChannelId = 'notify_task_channel';

const AndroidNotificationChannel _classChannel = AndroidNotificationChannel(
  _classChannelId,
  'แจ้งเตือนการเข้าเรียน',
  description: 'แจ้งเตือนเข้าเรียนล่วงหน้า',
  importance: Importance.max,
);

const AndroidNotificationChannel _taskChannel = AndroidNotificationChannel(
  _taskChannelId,
  'แจ้งเตือนงาน',
  description: 'แจ้งเตือนงานที่ต้องทำ',
  importance: Importance.max,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("📩 Background message received: ${message.messageId}");
  }
}

class NotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iOSInit,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    final androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_classChannel);
    await androidPlugin?.createNotificationChannel(_taskChannel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (kDebugMode) {
        print("🔔 Foreground notification received: ${message.data}");
      }

      final notification = message.notification;
      final data = message.data;

      final title = notification?.title ?? data['title'];
      final body = notification?.body ?? data['body'];
      final type = data['type'] ?? 'class';

      AndroidNotificationChannel selectedChannel =
          (type == 'task') ? _taskChannel : _classChannel;

      int notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      if (title != null && body != null) {
        await flutterLocalNotificationsPlugin.show(
          notificationId,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              selectedChannel.id,
              selectedChannel.name,
              channelDescription: selectedChannel.description,
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print("📲 Notification opened: ${message.data}");
      }
    });
  }

  Future<void> initTokenManagement(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final currentToken = await _firebaseMessaging.getToken();
    final lastToken = prefs.getString('fcm_token');

    debugPrint('🎯 currentToken = $currentToken');
    debugPrint('📦 lastToken = $lastToken');

    if (currentToken == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('Users').doc(email).get();
    final tokens = List<String>.from(userDoc.data()?['tokens'] ?? []);

    final shouldSave =
        currentToken != lastToken || !tokens.contains(currentToken);

    if (shouldSave) {
      debugPrint('🔄 Token changed or missing in Firestore → update required');

      if (lastToken != null && lastToken != currentToken) {
        await _deleteTokenFromFirestore(email, lastToken);
      }

      await _saveTokenToFirestore(email, currentToken);
      await prefs.setString('fcm_token', currentToken);
    } else {
      debugPrint('✅ No change and token exists → skip saving');
    }
  }

  Future<void> ensurePermissionAndInit(String email) async {
    NotificationSettings settings =
        await _firebaseMessaging.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.notDetermined ||
        settings.authorizationStatus == AuthorizationStatus.denied) {
      settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await initTokenManagement(email);
    }
  }

  Future<void> _saveTokenToFirestore(String email, String token) async {
    try {
      debugPrint("📤 Saving token $token for $email");

      await FirebaseFirestore.instance.collection('Users').doc(email).set(
        {
          'tokens': FieldValue.arrayUnion([token]),
          'platforms': {
            token: Platform.isIOS
                ? 'ios'
                : (Platform.isAndroid ? 'android' : 'web'),
          },
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      debugPrint("✅ Token saved successfully");
    } catch (e) {
      debugPrint("❌ Error saving token: $e");
    }
  }

  Future<void> _deleteTokenFromFirestore(String email, String token) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(email).update(
        {
          'tokens': FieldValue.arrayRemove([token]),
          'platforms.$token': FieldValue.delete(),
        },
      );
    } catch (e) {
      return;
    }
  }
}
