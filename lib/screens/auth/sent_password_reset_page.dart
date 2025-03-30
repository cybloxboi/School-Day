import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:school_day/screens/auth/login_page.dart';
import 'package:school_day/styles/styles.dart';

class SentPasswordResetPage extends StatefulWidget {
  const SentPasswordResetPage({super.key, required this.email});

  final String email;

  @override
  State<SentPasswordResetPage> createState() => _SentPasswordResetPageState();
}

class _SentPasswordResetPageState extends State<SentPasswordResetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ลืมรหัสผ่าน',
          style: textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            spacing: 32,
            children: [
              LottieBuilder.asset(
                'assets/animations/password_reset.json',
                width: 280,
                height: 280,
                frameRate: const FrameRate(120),
              ),
              Text(
                'เราได้ทำการส่งลิงค์รีเซ็ตรหัสผ่านให้แล้ว ลองเช็คอีเมลดูสิ!',
                style: textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Center(
                      child: LoadingAnimationWidget.fourRotatingDots(
                        color: primaryColor,
                        size: 80,
                      ),
                    ),
                  );

                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: widget.email,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('ส่งอีเมลใหม่'),
              ),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                },
                child: const Text('กลับไปหน้าล็อคอิน'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
