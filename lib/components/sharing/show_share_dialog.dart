import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:school_day/styles/styles.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareData(BuildContext context, String type, String docId) async {
  final firestore = FirebaseFirestore.instance;

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Error();
    }

    final docSnap = await firestore
        .collection('Users')
        .doc(user.email)
        .collection(type == 'timetable' ? 'Timetables' : 'Todos')
        .doc(docId)
        .get();

    final sharedDocRef = firestore.collection('SharedLinks').doc();
    await sharedDocRef.set({
      'type': type,
      'data': docSnap.data(),
      'owner': user.displayName ?? user.email ?? 'Unknown',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
    });

    if (context.mounted) {
      Navigator.of(context).pop();
    }

    final link = 'https://school-day-a1e87.web.app/share/${sharedDocRef.id}';

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'ลิงก์สำหรับแชร์',
            style: textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SelectableText(link),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: link));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('คัดลอกลิงก์แล้ว')),
                );
              },
              child: const Text('คัดลอกลิงก์'),
            ),
            if (!kIsWeb)
              TextButton(
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(text: link),
                  );
                },
                child: const Text('แชร์ผ่านแอป'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }
}
