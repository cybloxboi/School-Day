import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:school_day/components/login_widget.dart';
import 'package:school_day/screens/timetables/timetable_page.dart';
import 'package:school_day/styles/styles.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Future logIn(BuildContext context) async {
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

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (context.mounted) {
        Navigator.pop(context);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TimetablePage(),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ล็อคอินสำเร็จ! >3')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        Navigator.pop(context);

        String errorMessage;

        if (e.code == 'invalid-credential') {
          errorMessage = 'อีเมล หรือรหัสผ่านไม่ถูกต้อง โปรดลองใหม่อีกครั้ง';
        } else {
          errorMessage = 'เกิดข้อผิดพลาดบางอย่างเกิดขึ้น โปรดลองใหม่อีกครั้ง';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 1000) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 34,
                        ),
                        Flexible(
                          flex: 1,
                          child: LottieBuilder.network(
                            width: 600,
                            height: 600,
                            'https://lottie.host/074b1f4b-b1a1-4412-b0f1-5048bb949f6a/6bx2geWlXV.json',
                          ),
                        ),
                        const SizedBox(
                          width: 34,
                        ),
                        Flexible(
                          flex: 1,
                          child: LoginWidget(
                            formKey: _formKey,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            onLogin: (context) => logIn(context),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LottieBuilder.network(
                          width: 400,
                          height: 400,
                          'https://lottie.host/074b1f4b-b1a1-4412-b0f1-5048bb949f6a/6bx2geWlXV.json',
                        ),
                        const SizedBox(height: 16),
                        Flexible(
                          child: LoginWidget(
                            formKey: _formKey,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            onLogin: (context) => logIn(context),
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
