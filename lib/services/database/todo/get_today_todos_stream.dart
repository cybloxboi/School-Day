import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_day/data/todo.dart';

Stream<List<Todo>> getTodayTodosStream(String email) {
  final today = DateTime.now();

  final todosRef = FirebaseFirestore.instance
      .collection('Users')
      .doc(email)
      .collection('Todos');

  return todosRef.snapshots().map((snapshot) {
    final List<Todo> todayTodos = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final categoryName = data['name'] as String? ?? 'ไม่รู้จัก';
      final todos = (data['todos'] as List<dynamic>? ?? []);

      for (final rawTodo in todos) {
        final todoMap = Map<String, dynamic>.from(rawTodo);
        todoMap['name'] = categoryName;

        final todo = Todo.fromJson(todoMap);

        if (todo.selectedDate != null) {
          final d = todo.selectedDate!;
          final isToday = d.year == today.year &&
              d.month == today.month &&
              d.day == today.day;

          if (isToday) {
            todayTodos.add(todo);
          }
        }
      }
    }

    return todayTodos;
  });
}
