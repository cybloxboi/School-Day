import 'package:flutter/material.dart';

Widget textField(
  TextEditingController controller,
  String hintText,
  IconData icon,
  double maxWidth,
  int maxLength, {
  bool isMultipleLine = false,
}) {
  return LayoutBuilder(
    builder: (context, snapshot) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: snapshot.maxWidth > 650 ? maxWidth : snapshot.maxWidth,
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                ),
                keyboardType: isMultipleLine ? TextInputType.multiline : null,
                maxLength: maxLength,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'โปรดกรอก$hintTextด้วยนะงับ';
                  }

                  return null;
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
