import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_day/data/todo.dart';
import 'package:school_day/services/database/user/user_document.dart';

class TodoDocument extends UserDocument {
  TodoDocument(super.email);

  Future<List<Map<String, dynamic>>> getTodoListFuture() async {
    final snapshot = await userDocument.get();
    final data = snapshot.data() as Map<String, dynamic>?;

    if (data == null || data['todoList'] == null) return [];

    return List<Map<String, dynamic>>.from(data['todoList']);
  }

  Stream getTodoList(Stream<DocumentSnapshot> userDocumentSnapshot) {
    return userDocumentSnapshot.map((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        List<dynamic> todoFirestore = data['todoList'] ?? [];
        List<Todo> todoList = todoFirestore
            .map((todo) => Todo.fromJson(todo as Map<String, dynamic>))
            .toList();

        return todoList;
      }

      return [];
    }).distinct();
  }

  Future<bool> addTodo({required Todo newTodo}) async {
    try {
      await userDocument.update({
        'todoList': FieldValue.arrayUnion([newTodo.toJson()]),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTodo({required Todo todo}) async {
    try {
      await userDocument.update(
        {
          'todoList': FieldValue.arrayRemove(
            [todo.toJson()],
          )
        },
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTodo({
    required Todo oldTodo,
    required Todo newTodo,
  }) async {
    try {
      await userDocument.update(
        {
          'todoList': FieldValue.arrayRemove([oldTodo.toJson()]),
        },
      );

      await userDocument.update(
        {
          'todoList': FieldValue.arrayUnion([newTodo.toJson()]),
        },
      );

      return true;
    } catch (e) {
      return false;
    }
  }
}
