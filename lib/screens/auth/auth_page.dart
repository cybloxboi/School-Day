import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:school_day/screens/auth/login_page.dart';
import 'package:school_day/screens/navigation_menu.dart';
import 'package:school_day/services/notification/notification_service.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }

            if (snapshot.data != null && snapshot.data!.emailVerified) {
              NotificationService().initTokenManagement(snapshot.data!.email!);
            }

            return const NavigationMenu();
          }

          return const LoginPage();
        },
      ),
    );
  }
}
