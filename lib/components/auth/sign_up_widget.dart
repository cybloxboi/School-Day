import 'package:flutter/material.dart';
import 'package:school_day/components/auth/validate.dart';
import 'package:school_day/styles/styles.dart';

class SignUpWidget extends StatefulWidget {
  const SignUpWidget({
    super.key,
    required this.formKey,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onSignUp,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final Function(BuildContext) onSignUp;

  @override
  State<SignUpWidget> createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> {
  String _password = '';

  @override
  void initState() {
    super.initState();

    widget.passwordController.addListener(() {
      setState(() {
        _password = widget.passwordController.text;
      });
    });

    widget.confirmPasswordController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
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
          height: 32,
        ),
        Form(
          key: widget.formKey,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 18,
              children: [
                TextFormField(
                  controller: widget.usernameController,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'ชื่อผู้ใช้งาน',
                  ),
                  keyboardType: TextInputType.name,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'โปรดระบุชื่อผู้ใช้งาน';
                    }

                    return null;
                  },
                ),
                TextFormField(
                  controller: widget.emailController,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'อีเมล',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'โปรดระบุอีเมล';
                    } else if (!isValidEmail(value)) {
                      return 'อีเมลไม่ถูกต้องน้า';
                    }

                    return null;
                  },
                ),
                TextFormField(
                  autofillHints: const [AutofillHints.newPassword],
                  controller: widget.passwordController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'รหัสผ่าน',
                  ),
                  keyboardType: TextInputType.visiblePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  obscureText: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'โปรดระบุรหัสผ่าน';
                    } else if (!isPasswordValid(value)) {
                      return 'รหัสผ่านยังไม่ปลอดภัยนะ';
                    }

                    return null;
                  },
                ),
                TextFormField(
                  autofillHints: const [AutofillHints.newPassword],
                  controller: widget.confirmPasswordController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'ยืนยันรหัสผ่าน',
                  ),
                  keyboardType: TextInputType.visiblePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  obscureText: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'โปรดระบุยืนยันรหัสผ่าน';
                    } else if (value != _password) {
                      return 'ยืนยันรหัสผ่านไม่ตรงกับรหัสผ่าน';
                    }

                    return null;
                  },
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
                        color: isPasswordValid(_password) ? Colors.green : null,
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
                                text: 'มีตัวอักษรพิมพ์ใหญ่อย่างน้อย 1 ตัวอักษร',
                                isValid: hasUpperCase(_password),
                              ),
                              PasswordRuleCheck(
                                text: 'มีตัวอักษรพิมพ์เล็กอย่างน้อย 1 ตัวอักษร',
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
                    if (widget.formKey.currentState!.validate()) {
                      widget.onSignUp(context);
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
        ),
      ],
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
