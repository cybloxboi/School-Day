import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:school_day/components/auth/sign_up_widget.dart';
import 'package:school_day/services/database/user/user_document.dart';
import 'package:school_day/styles/styles.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  Future signUp(BuildContext context) async {
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
      UserCredential? userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      User? user = userCredential.user;

      UserDocument userDocument = UserDocument(user!.email!);

      await userDocument.createUserDocument(
        username: _usernameController.text.trim(),
      );

      if (!context.mounted) return;
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      Navigator.pop(context);

      String errorMessage;

      if (e.code == 'email-already-in-use') {
        errorMessage = 'อีเมลนี้สมัครไปแล้วนะ ลองล็อคอินดูน้า';
      } else {
        errorMessage = 'เกิดข้อผิดพลาดบางอย่างเกิดขึ้น โปรดลองใหม่อีกครั้ง';
        debugPrint(e.code);
        debugPrint(e.message);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor,
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 820) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          flex: 1,
                          child: LottieBuilder.asset(
                            'assets/animations/signup.json',
                            width: 400,
                            height: 400,
                          ),
                        ),
                        Flexible(
                          flex: 1,
                          child: SignUpWidget(
                            formKey: _formKey,
                            usernameController: _usernameController,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            confirmPasswordController:
                                _confirmPasswordController,
                            onSignUp: (context) => signUp(context),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          flex: 1,
                          child: LottieBuilder.asset(
                            'assets/animations/signup.json',
                            width: 280,
                            height: 280,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Flexible(
                          child: SignUpWidget(
                            formKey: _formKey,
                            usernameController: _usernameController,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            confirmPasswordController:
                                _confirmPasswordController,
                            onSignUp: (context) => signUp(context),
                          ),
                        ),
                        const SizedBox(height: 16),
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
