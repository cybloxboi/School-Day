import 'package:flutter/material.dart';
import 'package:school_day/screens/todos/add_new_todo_page.dart';
import 'package:school_day/styles/styles.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  // late TodoDocument _todoDocument;
  // late final Stream<DocumentSnapshot> _userStream;

  @override
  void initState() {
    super.initState();

    // _todoDocument = TodoDocument(FirebaseAuth.instance.currentUser!.email!);
    // _userStream = _todoDocument.getUserDocumentSnapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'งาน',
          style: textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      backgroundColor: backgroundColor,
      body: ListView.builder(
        itemCount: 20,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('ชื่องาน'),
                        Spacer(),
                        Icon(Icons.schedule),
                        Text('เวลา'),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text('Detail'),
                    const Divider(),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return AddNewTodoPage();
                            },
                          ),
                        );
                      },
                      icon: Icon(Icons.add),
                      label: Text('Add'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
