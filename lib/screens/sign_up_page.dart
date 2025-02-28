import 'package:flutter/material.dart';
import 'package:school_day/components/is_vaild_email.dart';
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

  Future signUp() async {}

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
                              }

                              return null;
                            },
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: TextFormField(
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
                                        isVaild: hasMinLength(_password),
                                      ),
                                      PasswordRuleCheck(
                                        text:
                                            'มีตัวอักษรพิมพ์ใหญ่อย่างน้อย 1 ตัวอักษร',
                                        isVaild: hasUpperCase(_password),
                                      ),
                                      PasswordRuleCheck(
                                        text:
                                            'มีตัวอักษรพิมพ์เล็กอย่างน้อย 1 ตัวอักษร',
                                        isVaild: hasLowerCase(_password),
                                      ),
                                      PasswordRuleCheck(
                                        text: 'มีตัวเลขอย่างน้อย 1 ตัวอักษร',
                                        isVaild: hasNumber(_password),
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
                            _formKey.currentState!.validate();
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
    required this.isVaild,
  });

  final String text;
  final bool isVaild;

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
            isVaild ? Icons.check_circle : Icons.check_circle_outline_rounded,
            key: ValueKey(isVaild),
            color: isVaild ? primaryColor : Colors.grey,
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
