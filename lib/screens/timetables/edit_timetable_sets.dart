import 'package:flutter/material.dart';

class EditTimetableSets extends StatefulWidget {
  const EditTimetableSets({super.key});

  @override
  State<EditTimetableSets> createState() => _EditTimetableSetsState();
}

class _EditTimetableSetsState extends State<EditTimetableSets> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Text('หน้าแก้ชื่อชุดตารางเรียน'),
      ),
    );
  }
}
