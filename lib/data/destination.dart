import 'package:flutter/material.dart';

class Destination {
  const Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final Widget icon;
  final Widget selectedIcon;
}

const List<Destination> destinations = [
  Destination(
    'หน้าแรก',
    Icon(Icons.home_outlined),
    Icon(Icons.home_rounded),
  ),
  Destination(
    'ตารางเรียน',
    Icon(Icons.date_range_outlined),
    Icon(Icons.date_range_rounded),
  ),
  Destination(
    'งาน',
    Icon(Icons.sticky_note_2_outlined),
    Icon(Icons.sticky_note_2_rounded),
  ),
  Destination(
    'รูปโปรไฟล์',
    Icon(Icons.person_outline),
    Icon(Icons.person_rounded),
  ),
];
