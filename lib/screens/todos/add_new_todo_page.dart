import 'package:flutter/material.dart';
import 'package:school_day/styles/styles.dart';

class AddNewTodoPage extends StatefulWidget {
  const AddNewTodoPage({super.key});

  @override
  State<AddNewTodoPage> createState() => _AddNewTodoPageState();
}

class _AddNewTodoPageState extends State<AddNewTodoPage> {
  final _titleController = TextEditingController();
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'เพิ่มงานใหม่',
          style: textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
         centerTitle: false,
      actions: [
        
        Padding(
    padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
    child: ElevatedButton.icon(
          onPressed: () {
          },
          style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF874B57),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 0,
        ),
          icon: const Icon(Icons.save_rounded, color: Colors.white),
          label: const Text(
            'บันทึก',
            style: TextStyle(color: Colors.white),
          ),
    ),
        ),
      ],
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.book_rounded),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            hintText: 'ชื่องาน',
                            counterText: '0/50',
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.description_rounded),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            hintText: 'รายละเอียด',
                            counterText: '0/100',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    height: 32,
                    thickness: 1,
                    color: Colors.black26, 
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}





