import 'dart:async';

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
  bool _isDisabled = false;
  int _countdown = 0;
  Timer? _timer;

  void _disableButton() {
    setState(() {
      _isDisabled = true;
      _countdown = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  @override
  void initState() {
    super.initState();
    _disableButton();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              spacing: 32,
              children: [
                LottieBuilder.asset(
                  'assets/animations/loading.json',
                  width: 280,
                  height: 280,
                  frameRate: const FrameRate(120),
                ),
                Text(
                  'เราได้ทำการส่งลิงค์รีเซ็ตรหัสผ่านให้แล้ว ลองเช็คอีเมลดูสิ!',
                  style: textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  softWrap: true,
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'หากไม่เจออีเมลให้ลองเช็คจดหมายขยะ (Spam) หรือคลิก ส่งอีเมลใหม่ ใน 1 นาที',
                  softWrap: true,
                  textAlign: TextAlign.center,
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

                              await FirebaseAuth.instance
                                  .sendPasswordResetEmail(
                                email: widget.email,
                              );

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
