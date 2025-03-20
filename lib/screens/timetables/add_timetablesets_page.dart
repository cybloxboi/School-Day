import 'package:flutter/material.dart';
import 'package:school_day/styles/styles.dart';

class AddTimetablesetsPage extends StatefulWidget {
  const AddTimetablesetsPage({super.key});

  @override
  State<AddTimetablesetsPage> createState() => _AddTimetablesetsPageState();
}

class _AddTimetablesetsPageState extends State<AddTimetablesetsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: backgroundColor,
      body: const Center(
        child: Text('หน้าเพิ่มตารางเรียนใหม่'),
      ),
    );
  }
}
