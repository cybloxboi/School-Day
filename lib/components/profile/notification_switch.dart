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
          .getNotificationSettings(userDocument.getUserDocumentSnapshots()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return LoadingAnimationWidget.fourRotatingDots(
            color: primaryColor,
            size: 20,
          );
        }

        final data = snapshot.data!;
        final bool isNotifyTimetable = data['isNotifyTimetable'] ?? false;
        final bool isNotifyTodos = data['isNotifyTodos'] ?? false;

        return Column(
          children: [
            SwitchListTile(
              value: isNotifyTimetable,
              onChanged: (value) async {
                await userDocument.updateIsNotifyTimetable(value);
              },
              title: Text(
                'เปิด/ปิดการแจ้งเตือนตารางเรียน',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            SwitchListTile(
              value: isNotifyTodos,
              onChanged: (value) async {
                await userDocument.updateIsNotifyTodos(value);
              },
              title: Text(
                'เปิด/ปิดการแจ้งเตือนงาน',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        );
      },
    );
  }
}
