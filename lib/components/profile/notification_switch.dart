import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:school_day/services/database/user/user_document.dart';
import 'package:school_day/styles/styles.dart';

class NotificationSwitch extends StatefulWidget {
  const NotificationSwitch({super.key});

  @override
  State<NotificationSwitch> createState() => _NotificationSwitchState();
}

class _NotificationSwitchState extends State<NotificationSwitch> {
  final userDocument = UserDocument(FirebaseAuth.instance.currentUser!.email!);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: userDocument
          .getIsNotifyTimetable(userDocument.getUserDocumentSnapshots()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return LoadingAnimationWidget.fourRotatingDots(
            color: primaryColor,
            size: 20,
          );
        }

        final bool isNotify = snapshot.data ?? false;

        return SwitchListTile(
          value: isNotify,
          onChanged: (value) {
            userDocument.updateIsNotifyTimetable(value);
          },
          title: Text(
            'เปิด/ปิดการแจ้งเตือนตารางเรียน',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      },
    );
  }
}
