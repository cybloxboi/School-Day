import 'dart:async';
import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:school_day/screens/auth/auth_page.dart';
import 'package:school_day/screens/share/share_view_page.dart';
import 'package:school_day/services/notification/notification_service.dart';
import 'package:uni_links/uni_links.dart';
import 'firebase_options.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  if (!kIsWeb) {
    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
    }

    final notificationService = NotificationService();
    await notificationService.initNotifications();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  await initializeDateFormatting('th_TH', null);
  Intl.defaultLocale = 'th_TH';

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final GoRouter _router;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();

    _router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const AuthPage(),
        ),
        GoRoute(
          path: '/share/:shareId',
          builder: (context, state) {
            final shareId = state.pathParameters['shareId']!;
            return ShareViewPage(shareId: shareId);
          },
        ),
      ],
    );

    _initUniLinks();
  }

  void _initUniLinks() async {
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      // error handling
    }

    _sub = uriLinkStream.listen((uri) {
      if (uri != null) {
        _handleUri(uri);
      }
    }, onError: (err) {
      // error handling
    });
  }

  void _handleUri(Uri uri) {
    debugPrint('Incoming URI: $uri');
    debugPrint('Path segments: ${uri.pathSegments}');

    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      final shareIndex = segments.indexOf('share');
      if (shareIndex != -1 && shareIndex + 1 < segments.length) {
        final shareId = segments[shareIndex + 1];
        _router.go('/share/$shareId');
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerDelegate: _router.routerDelegate,
      routeInformationParser: _router.routeInformationParser,
      routeInformationProvider: _router.routeInformationProvider,
      title: 'School Day',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
                  minScaleFactor: 0,
                  maxScaleFactor: 0.8,
                ),
          ),
          child: child!,
        );
      },
      supportedLocales: const [
        Locale('th', 'TH'),
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.ibmPlexSansThaiTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
