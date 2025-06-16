import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:school_day/screens/auth/login_page.dart';
import 'package:school_day/screens/navigation_menu.dart';
import 'package:school_day/styles/styles.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isEmailVerified = false;
  bool isVerifying = false;
  Timer? _timer;
  Timer? _countdownTimer;
  int _countdown = 0;
  bool _isDisabled = false;

  @override
  void initState() {
    super.initState();

    _checkEmailVerified();
    _startVerificationCheck();
    _disableButton();
  }

  void _disableButton() {
    setState(() {
      _isDisabled = true;
      _countdown = 60;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _isDisabled = false;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _checkEmailVerified() async {
    User? user = _auth.currentUser;
    await user?.reload();

    setState(() {
      isEmailVerified = user?.emailVerified ?? false;
    });

    if (isEmailVerified) {
      _timer?.cancel();
      _countdownTimer?.cancel();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const NavigationMenu(),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerified();
    });
  }

  Future<void> _sendVerificationEmail() async {
    User? user = _auth.currentUser;

    if (user != null && !user.emailVerified) {
      setState(() => isVerifying = true);
      await user.sendEmailVerification();
      setState(() => isVerifying = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ยืนยันอีเมล',
          style: textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                LottieBuilder.asset(
                  'assets/animations/loading.json',
                  width: 280,
                  height: 280,
                  frameRate: const FrameRate(120),
                ),
                const SizedBox(
                  height: 32,
                ),
                Text(
                  'เราได้ทำการส่งลิงค์ยืนยันอีเมลให้แล้ว ลองเช็คอีเมลดูสิ!',
                  style: textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  softWrap: true,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 32,
                ),
                const Text(
                  'หากไม่เจออีเมลให้ลองเช็คจดหมายขยะ (Spam) หรือคลิก ส่งอีเมลใหม่ ใน 1 นาที',
                  softWrap: true,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 16,
                ),
                const Text(
                  'หากยืนยันอีเมลแล้ว โปรดรอสักครู่ ประมาณ 3 วินาที เราจะทำการเข้าสู่ระบบให้คุณ :>',
                  softWrap: true,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 32,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: _isDisabled
                          ? null
                          : () async {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => Center(
                                  child:
                                      LoadingAnimationWidget.fourRotatingDots(
                                    color: primaryColor,
                                    size: 80,
                                  ),
                                ),
                              );

                              await _sendVerificationEmail();

                              if (context.mounted) {
                                Navigator.pop(context);
                                _disableButton();
                              }
                            },
                      child: const Text('ส่งอีเมลใหม่'),
                    ),
                    if (_isDisabled) Text('$_countdown วินาที'),
                  ],
                ),
                const SizedBox(
                  height: 32,
                ),
                FilledButton.tonal(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('กลับไปหน้าล็อคอิน'),
                ),
                const SizedBox(
                  height: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
