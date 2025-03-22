import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:school_day/components/is_valid_email.dart';
import 'package:school_day/services/timetable_database.dart';
import 'package:school_day/styles/styles.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _password = '';

  final _formKey = GlobalKey<FormState>();

  bool hasUpperCase(String password) => password.contains(RegExp(r'[A-Z]'));

  bool hasLowerCase(String password) => password.contains(RegExp(r'[a-z]'));

  bool hasNumber(String password) => password.contains(RegExp(r'[0-9]'));

  bool hasMinLength(String password) => password.length >= 6;

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
        password: _password.trim(),
      );

      await createUserDocument(userCredential);

      FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สร้างแอคเคาท์สำเร็จ! :3')),
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      Navigator.pop(context);

      String errorMessage;

      if (e.code == 'email-already-in-use') {
        errorMessage = 'อีเมลนี้สมัครไปแล้วนะ ลองล็อคอินดูน้า';
      } else {
        errorMessage = 'เกิดข้อผิดพลาดบางอย่างเกิดขึ้น โปรดลองใหม่อีกครั้ง';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  bool isPasswordValid(String password) {
    return hasUpperCase(password) &&
        hasLowerCase(password) &&
        hasNumber(password) &&
        hasMinLength(password);
  }

  @override
  void initState() {
    super.initState();

    _passwordController.addListener(() {
      setState(() {
        _password = _passwordController.text;
      });
    });

    _confirmPasswordController.addListener(() {
      setState(() {});
    });
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 16,
                children: [
                  Text(
                    'ยินดีต้อนรับ',
                    style: textTheme.headlineLarge,
                  ),
                  Text(
                    'มาสมัครแอคเคาท์กัน ^w^',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 16,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: TextFormField(
                            controller: _emailController,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'อีเมล',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'โปรดระบุอีเมล';
                              } else if (!isValidEmail(value)) {
                                return 'อีเมลไม่ถูกต้องน้า';
                              }

                              return null;
                            },
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: TextFormField(
                            autofillHints: const [AutofillHints.newPassword],
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'รหัสผ่าน',
                            ),
                            keyboardType: TextInputType.visiblePassword,
                            autocorrect: false,
                            enableSuggestions: false,
                            obscureText: true,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'โปรดระบุรหัสผ่าน';
                              } else if (!isPasswordValid(value)) {
                                return 'รหัสผ่านยังไม่ปลอดภัยนะ';
                              }

                              return null;
                            },
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: TextFormField(
                            autofillHints: const [AutofillHints.newPassword],
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'ยืนยันรหัสผ่าน',
                            ),
                            keyboardType: TextInputType.visiblePassword,
                            autocorrect: false,
                            enableSuggestions: false,
                            obscureText: true,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'โปรดระบุยืนยันรหัสผ่าน';
                              } else if (value != _password) {
                                return 'ยืนยันรหัสผ่านไม่ตรงกับรหัสผ่าน';
                              }

                              return null;
                            },
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: ExpansionTile(
                            leading: const Icon(Icons.password),
                            title: Text(
                              isPasswordValid(_password)
                                  ? 'รหัสผ่านดูดีเลย :3'
                                  : 'โอ้ ลองคิดรหัสผ่านใหม่นะ',
                              style: textTheme.bodySmall!.copyWith(
                                color: isPasswordValid(_password)
                                    ? Colors.green
                                    : null,
                              ),
                            ),
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    spacing: 8,
                                    children: [
                                      PasswordRuleCheck(
                                        text: 'มีอย่างน้อย 6 ตัวอักษร',
                                        isValid: hasMinLength(_password),
                                      ),
                                      PasswordRuleCheck(
                                        text:
                                            'มีตัวอักษรพิมพ์ใหญ่อย่างน้อย 1 ตัวอักษร',
                                        isValid: hasUpperCase(_password),
                                      ),
                                      PasswordRuleCheck(
                                        text:
                                            'มีตัวอักษรพิมพ์เล็กอย่างน้อย 1 ตัวอักษร',
                                        isValid: hasLowerCase(_password),
                                      ),
                                      PasswordRuleCheck(
                                        text: 'มีตัวเลขอย่างน้อย 1 ตัวอักษร',
                                        isValid: hasNumber(_password),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              signUp(context);
                            }
                          },
                          child: Text(
                            'สมัคร',
                            style: textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordRuleCheck extends StatelessWidget {
  const PasswordRuleCheck({
    super.key,
    required this.text,
    required this.isValid,
  });

  final String text;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: child,
          ),
          child: Icon(
            isValid ? Icons.check_circle : Icons.check_circle_outline_rounded,
            key: ValueKey(isValid),
            color: isValid ? primaryColor : Colors.grey,
            size: 20,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall!.copyWith(fontSize: 14),
            softWrap: true,
          ),
        ),
      ],
    );
  }
}
