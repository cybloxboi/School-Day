import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const String _channelId = 'notify_class_time_channel';
const String _channelName = 'แจ้งเตือนการเข้าเรียน';
const String _channelDescription = 'แจ้งเตือนเข้าเรียนล่วงหน้า';

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  _channelId,
  _channelName,
  description: _channelDescription,
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
  final AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'notify_class_time_channel',
    'แจ้งเตือนการเข้าเรียน',
    description: 'แจ้งเตือนเข้าเรียนล่วงหน้า',
    importance: Importance.max,
  );

  Future<void> initNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: DarwinInitializationSettings(),
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (kDebugMode) {
        print("🔔 Foreground notification received");
      }

      final notification = message.notification;
      final data = message.data;

      final title = notification?.title ?? data['title'];
      final body = notification?.body ?? data['body'];

      if (title != null && body != null) {
        await flutterLocalNotificationsPlugin.show(
          0,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: _channel.importance,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
        );
      }
    });
  }

  Future<void> initTokenManagement(String email) async {
    if (!Platform.isAndroid) {
      return;
    }

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
    if (kIsWeb) {
      return;
    }

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
