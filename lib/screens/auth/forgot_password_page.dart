import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:school_day/components/validate.dart';
import 'package:school_day/screens/auth/sent_password_reset_page.dart';
import 'package:school_day/styles/styles.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.email});

  final String? email;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
  }

  Future<void> passwordReset(BuildContext context) async {
    try {
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
        email: _emailController.text.trim(),
      );

      if (context.mounted) {
        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SentPasswordResetPage(
              email: _emailController.text.trim(),
            ),
          ),
        );
      }
    } on FirebaseAuthException {
      return;
    }
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            spacing: 32,
            children: [
              LottieBuilder.asset(
                'assets/animations/forgot_password.json',
                width: 280,
                height: 280,
                frameRate: const FrameRate(120),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800 &&
                      constraints.maxHeight > 300) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: statement(),
                        ),
                        const SizedBox(width: 64),
                        Flexible(
                          child: formInput(),
                        ),
                      ],
                    );
                  }

                  return Column(
                    spacing: 32,
                    children: [
                      statement(),
                      formInput(),
                    ],
                  );
                },
              ),
              const SizedBox(
                height: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget statement() {
    return Column(
      spacing: 32,
      children: [
        Text(
          'ลืมรหัสผ่านงั้นหรอ? ไม่ต้องห่วง!',
          style: textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
          softWrap: true,
        ),
        const Text(
          'เพียงแค่กรอกอีเมลที่คุณสมัครไว้ เพื่อส่งลิงค์รีเซ็ตรหัสผ่าน',
          textAlign: TextAlign.center,
          softWrap: true,
        ),
      ],
    );
  }

  Widget formInput() {
    return Column(
      spacing: 32,
      children: [
        Form(
          key: _formKey,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: TextFormField(
              controller: _emailController,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'อีเมล',
              ),
              keyboardType: TextInputType.emailAddress,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "โปรดระบุอีเมล";
                } else if (!isValidEmail(value)) {
                  return "อีเมลไม่ถูกต้องน้า";
                }

                return null;
              },
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              passwordReset(context);
            }
          },
          child: const Text('รีเซ็ตรหัสผ่าน'),
        ),
      ],
    );
  }
}
