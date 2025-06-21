import 'package:flutter/material.dart';

class ActionDisplay {
  final String label;
  final IconData icon;

  const ActionDisplay(this.label, this.icon);
}

ActionDisplay getActionDisplay(String action, String type) {
  final baseMap = {
    'add': ActionDisplay('เพิ่ม', Icons.add_rounded),
    'update': ActionDisplay('แก้ไข', Icons.edit_rounded),
    'delete': ActionDisplay('ลบ', Icons.delete_rounded),
  };

  final suffix = type == 'timetable' ? 'ตารางเรียน' : 'งาน';
  final base = baseMap[action];
  if (base == null) {
    throw ArgumentError('Unknown action: $action');
  }

  return ActionDisplay('${base.label}$suffix', base.icon);
}
