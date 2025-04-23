import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:school_day/screens/auth/email_verification_page.dart';
import 'package:school_day/screens/auth/login_page.dart';
import 'package:school_day/screens/navigation_menu.dart';

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

            if (!snapshot.data!.emailVerified) {
              snapshot.data!.sendEmailVerification();
              return const EmailVerificationPage();
            }

            return const NavigationMenu();
          }

          return const LoginPage();
        },
      ),
    );
  }
}
