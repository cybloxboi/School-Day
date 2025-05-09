import 'package:flutter/material.dart';

class ActionDisplay {
  final String label;
  final IconData icon;

  const ActionDisplay(this.label, this.icon);
}

const Map<String, ActionDisplay> actionMap = {
  'add': ActionDisplay('เพิ่มงาน', Icons.add_rounded),
  'update': ActionDisplay('แก้ไขงาน', Icons.edit_rounded),
  'delete': ActionDisplay('ลบงาน', Icons.delete_rounded),
};
