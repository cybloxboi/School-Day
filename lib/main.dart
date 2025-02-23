import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:school_day/screens/login_page.dart';
import 'package:school_day/styles/text.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.light,
        ),
        textTheme: textTheme,
      ),
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        backgroundColor: Color.fromARGB(80, 255, 209, 220),
        body: LoginPage(),
      ),
    );
  }
}
