import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:school_day/main.dart';
import 'package:school_day/styles/styles.dart';

class AuthService {
  Future<void> signup({
    required String email,
    required String password,
  }) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String message = '';

      if (e.code == 'email-already-in-use') {
        message = 'มีอีเมลนี้อยู่แล้ว';
      } else if (e.code == 'weak-password') {
        message = 'รหัสผ่านนี้อ่อนแอเกินไป';
      }

      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            message != '' ? message : e.code,
            style: textTheme.bodySmall,
          ),
        ),
      );

      print(e.code);
    }
  }
}
