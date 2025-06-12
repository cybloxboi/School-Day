import 'package:cloud_firestore/cloud_firestore.dart';

class TodoDocument {
  final firestore = FirebaseFirestore.instance;

  late DocumentReference userDoc;
  late CollectionReference todos;
  late DocumentReference todoDoc;

  final String email;

  DocumentReference getUserDocument(String email) {
    return firestore.collection('Users').doc(email);
  }

  CollectionReference getUserTodosCollection(
    DocumentReference userDocument,
  ) {
    return userDocument.collection('Todos');
  }

  DocumentReference getUserTodoDoc([String? path]) {
    return todos.doc(path);
  }

  TodoDocument({required this.email}) {
    userDoc = getUserDocument(email);
    todos = getUserTodosCollection(userDoc);
    todoDoc = getUserTodoDoc();
  }

  Stream<DocumentSnapshot> getUserDocumentSnapshots() {
    return userDoc.snapshots();
  }

  Stream getCurrentTodosID(Stream<DocumentSnapshot> userDocumentSnapshot) {
    return userDocumentSnapshot.map((snapshot) {
      if (snapshot.exists) {
        return snapshot['currentCategoryID'];
      } else {
        return null;
      }
    }).distinct();
  }

  Future<void> updateCurrentTodosID(String todosID) async {
    try {
      await userDoc.update({'currentCategoryID': todosID});
    } catch (e) {
      return;
    }
  }
}
