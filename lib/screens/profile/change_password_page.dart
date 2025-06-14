import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:school_day/styles/styles.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();

  Future<bool> reauthenticateUser(String currentPassword) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> changePassword(String newPassword) async {
    try {
      await user.updatePassword(newPassword);
    } catch (e) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'เปลี่ยนรหัสผ่าน',
          style: textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  bool isPasswordCorrect = await reauthenticateUser(
                    _oldPasswordController.text.trim(),
                  );

                  if (isPasswordCorrect) {
                    debugPrint('Password Correct!');
                  } else {
                    debugPrint('Not Correct!');
                  }
                }
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('บันทึก'),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _oldPasswordController,
                    decoration: const InputDecoration(
                      hintText: 'รหัสผ่านเดิม',
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'กรุณากรอกรหัสผ่านเดิม';
                      }
                  
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
