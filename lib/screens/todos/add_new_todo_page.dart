import 'package:flutter/material.dart';

class AddNewTodoPage extends StatefulWidget {
  const AddNewTodoPage({super.key});

  @override
  State<AddNewTodoPage> createState() => _AddNewTodoPageState();
}

class _AddNewTodoPageState extends State<AddNewTodoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Text('Hello'),
    );
  }
}
