import 'package:flutter/material.dart';
import 'package:school_day/components/validate.dart';
import 'package:school_day/screens/auth/sign_up_page.dart';
import 'package:school_day/styles/styles.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.onLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final Function(BuildContext) onLogin;

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ยินดีต้อนรับ',
            style: textTheme.headlineLarge,
          ),
          Text(
            'โปรดกรอกข้อมูลเข้าสู่ระบบ',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Form(
            key: widget.formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 32,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: TextFormField(
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
                        return "โปรดระบุอีเมล";
                      } else if (!isValidEmail(value)) {
                        return "อีเมลไม่ถูกต้องน้า";
                      }

                      return null;
                    },
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: TextFormField(
                    controller: widget.passwordController,
                    autofillHints: const [AutofillHints.password],
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
                        return "โปรดระบุรหัสผ่าน";
                      }

                      return null;
                    },
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    if (widget.formKey.currentState!.validate()) {
                      widget.onLogin(context);
                    }
                  },
                  child: Text(
                    'ล็อคอิน',
                    style: textTheme.bodySmall,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 24,
                  children: [
                    Text(
                      'ยังไม่มีสมาชิกหรอ?',
                      style: textTheme.bodySmall,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpPage(),
                          ),
                        );
                      },
                      child: Text(
                        'สมัครเลย!',
                        style: textTheme.bodySmall!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
