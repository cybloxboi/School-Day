import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:school_day/screens/auth/email_verification_page.dart';
import 'package:school_day/screens/auth/login_page.dart';
import 'package:school_day/screens/navigation_menu.dart';
import 'package:school_day/styles/styles.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.fourRotatingDots(
                color: primaryColor,
                size: 80,
              ),
            );
          }

          if (snapshot.hasData) {
            final user = snapshot.data!;
            
            if (!user.emailVerified) {
              user.sendEmailVerification();
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
