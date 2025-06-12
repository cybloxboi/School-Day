import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_day/services/database/todo/todo_document.dart';

class CategoryInfo {
  final String id;
  final String name;

  CategoryInfo({required this.id, required this.name});

  factory CategoryInfo.fromFirestore(DocumentSnapshot doc) {
    return CategoryInfo(
      id: doc.id,
      name: doc['name'] ?? 'ไม่มีชื่อ',
    );
  }
}

class CategoryDocument extends TodoDocument {
  CategoryDocument({required super.email});

  Stream<QuerySnapshot> getCategoryQuerySnapshots() {
    return getUserTodosCollection(userDoc).snapshots();
  }

  Stream<List<CategoryInfo>> fetchCategories(
    Stream<QuerySnapshot> todosQuerySnapshots,
  ) {
    return todosQuerySnapshots.map((snapshot) {
      return snapshot.docs.map((doc) {
        return CategoryInfo(
          id: doc.id,
          name: doc['name'] as String,
        );
      }).toList();
    }).distinct();
  }

  Future<void> createNewCategory({required String name}) async {
    try {
      await userDoc.set({
        'name': name,
        'createdAt': Timestamp.now(),
        'todos': [],
      });
    } catch (e) {
      return;
    }
  }

  Future<void> deleteCategory({required String categoryID}) async {
    DocumentReference categoryDoc = getUserTodoDoc(categoryID);

    try {
      await categoryDoc.delete();
    } catch (e) {
      return;
    }
  }

  Future<void> updateCategory({
    required String categoryID,
    required String name,
  }) async {
    DocumentReference categoryDoc = getUserTodoDoc(categoryID);

    try {
      categoryDoc.update({'name': name});
    } catch (e) {
      return;
    }
  }
}
