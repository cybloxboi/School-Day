import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_day/data/todo.dart';
import 'package:school_day/services/database/todo/todo_document.dart';

class TodoEntry extends TodoDocument {
  String categoryID;

  TodoEntry({required super.email, required this.categoryID});

  Stream<DocumentSnapshot> getTodoDocumentSnapshots() {
    return todoDoc.snapshots();
  }

  Stream<List<Todo>> fetchTodos(
    Stream<DocumentSnapshot> todoDocumentSnapshots,
  ) {
    return todoDocumentSnapshots.map((snapshot) {
      if (!snapshot.exists) return <Todo>[];

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      List<dynamic> todosData = data['todos'] ?? [];
      List<Todo> todos = todosData
          .map((todo) => Todo.fromJson(todo as Map<String, dynamic>))
          .toList();

      return todos;
    }).distinct();
  }

  Future<bool> addTodo({required Todo newTodo, required categoryID}) async {
    try {
      todoDoc = getUserTodoDoc(categoryID);

      await todoDoc.set({
        'todos': FieldValue.arrayUnion([newTodo.toJson()])
      }, SetOptions(merge: true));

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
      final todoDoc = getUserTodoDoc(categoryID);
      final snapshot = await todoDoc.get();

      if (!snapshot.exists) {
        return false;
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final List<dynamic> todosRaw = data['todos'] ?? [];

      List<Todo> todos = todosRaw
          .map((e) => Todo.fromJson(e as Map<String, dynamic>))
          .toList();

      final index = todos.indexWhere((todo) => todo.id == oldTodo.id);

      if (index == -1) {
        return false;
      }

      todos[index] = newTodo;

      await todoDoc.update({
        'todos': todos.map((t) => t.toJson()).toList(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTodo({
    required Todo todo,
  }) async {
    try {
      final todoDoc = FirebaseFirestore.instance
          .collection('Users')
          .doc(email)
          .collection('Todos')
          .doc(categoryID);
      final docSnap = await todoDoc.get();

      if (!docSnap.exists) return false;

      final data = docSnap.data() as Map<String, dynamic>;
      final todosRaw = data['todos'] as List<dynamic>? ?? [];

      List<Map<String, dynamic>> todos =
          todosRaw.map((item) => Map<String, dynamic>.from(item)).toList();

      todos.removeWhere((t) => t['id'] == todo.id);

      await todoDoc.update({'todos': todos});
      return true;
    } catch (e) {
      return false;
    }
  }
}
