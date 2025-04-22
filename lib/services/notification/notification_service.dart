import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("📩 Background message received: ${message.messageId}");
  }
}

class NotificationService {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await flutterLocalNotificationsPlugin.initialize(initSettings);

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
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    });
  }

  Future<void> initTokenManagement(String email) async {
    final prefs = await SharedPreferences.getInstance();

    final currentToken = await _firebaseMessaging.getToken();
    final lastToken = prefs.getString('fcm_token');

    if (currentToken != null && currentToken != lastToken) {
      if (lastToken != null) {
        await _deleteTokenFromFirestore(email, lastToken);
      }

      await _saveTokenToFirestore(email, currentToken);
      await prefs.setString('fcm_token', currentToken);
    }

    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      final oldToken = prefs.getString('fcm_token');

      if (oldToken != null && oldToken != newToken) {
        await _deleteTokenFromFirestore(email, oldToken);
      }

      await _saveTokenToFirestore(email, newToken);
      await prefs.setString('fcm_token', newToken);
    });
  }

  Future<void> _saveTokenToFirestore(String email, String token) async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(email)
        .collection('Tokens')
        .doc(token)
        .set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'platform':
          Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : 'web'),
    });
  }

  Future<void> _deleteTokenFromFirestore(String email, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(email)
          .collection('tokens')
          .doc(token)
          .delete();
    } catch (e) {
      return;
    }
  }
}
