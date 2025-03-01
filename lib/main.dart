import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:school_day/screens/auth_page.dart';
import 'package:school_day/styles/styles.dart';
import 'firebase_options.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
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
      home: const Scaffold(
        backgroundColor: backgroundColor,
        body: AuthPage(),
      ),
    );
  }
}
