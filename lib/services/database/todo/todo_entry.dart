import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
    required oldCategoryID,
    required Todo newTodo,
    required newCategoryID,
  }) async {
    try {
      final oldTodoDoc = getUserTodoDoc(oldCategoryID);
      final newTodoDoc = getUserTodoDoc(newCategoryID);

      if (oldCategoryID == newCategoryID) {
        await oldTodoDoc.update({
          'todos': FieldValue.arrayRemove([oldTodo.toJson()]),
        });

        await oldTodoDoc.update({
          'todos': FieldValue.arrayUnion([newTodo.toJson()]),
        });
      } else {
        await oldTodoDoc.update({
          'todos': FieldValue.arrayRemove([oldTodo.toJson()]),
        });

        await newTodoDoc.set({
          'todos': FieldValue.arrayUnion([newTodo.toJson()]),
        }, SetOptions(merge: true));
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
