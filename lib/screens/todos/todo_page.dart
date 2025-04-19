import 'package:flutter/material.dart';
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
      body: const Placeholder(),
    );
  }
}
