import 'package:cloud_firestore/cloud_firestore.dart';

class TodoDocument {
  final firestore = FirebaseFirestore.instance;

  late DocumentReference userDoc;
  late CollectionReference categories;
  late DocumentReference todoDoc;

  final String email;

  DocumentReference getUserDocument(String email) {
    return firestore.collection('Users').doc(email);
  }

  CollectionReference getUserCategoriesCollection(
    DocumentReference userDocument,
  ) {
    return userDocument.collection('Categories');
  }

  DocumentReference getUserTodoDoc([String? path]) {
    return categories.doc(path);
  }

  TodoDocument({required this.email}) {
    userDoc = getUserDocument(email);
    categories = getUserCategoriesCollection(userDoc);
    todoDoc = getUserTodoDoc();
  }

  Stream<DocumentSnapshot> getUserDocumentSnapshots() {
    return userDoc.snapshots();
  }

  Stream getCurrentCategoriesID(Stream<DocumentSnapshot> userDocumentSnapshot) {
    return userDocumentSnapshot.map((snapshot) {
      if (snapshot.exists) {
        return snapshot['currentCategoriesID'];
      } else {
        return null;
      }
    }).distinct();
  }

  Future<void> updateCurrentCategoriesID(String categoriesID) async {
    try {
      await userDoc.update({'currentCategoriesID': categoriesID});
    } catch (e) {
      return;
    }
  }
}
