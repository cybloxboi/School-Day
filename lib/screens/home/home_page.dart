import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:school_day/screens/auth/login_page.dart';
import 'package:school_day/services/notification/notification_service.dart';
import 'package:school_day/styles/styles.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future logOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!kIsWeb) NotificationService().cancelAllNotifications();

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ล็อคเอาท์สำเร็จ'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'หน้าแรก',
          style: textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () => logOut(context),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                'ล็อคเอาท์',
                style: textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: const Center(
        child: Text('SASSSSAA'),
      ),
    );
  }
}
