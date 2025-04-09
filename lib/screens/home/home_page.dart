import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:school_day/screens/auth/login_page.dart';
import 'package:school_day/services/notification/notification_service.dart';
import 'package:school_day/styles/styles.dart';
import 'package:intl/intl.dart';

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
    String today = DateFormat('d MMM yyyy').format(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'หน้าแรก',
          style: textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
  Scaffold.of(context).openDrawer();
          },
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
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.pink),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(backgroundColor: Colors.white,
                  child: Icon(Icons.person),)
                ],
              ),
            )
          ],
        ),
      ),
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('วันนี้',
                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                   ),
                   Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      today,
                      style: TextStyle(color: Colors.black),),
                   )
              ],
            )
          ],
        ),
        ),
      );
  }
}
