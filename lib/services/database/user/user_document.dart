import 'package:cloud_firestore/cloud_firestore.dart';

class UserDocument {
  final firestore = FirebaseFirestore.instance;

  late DocumentReference userDocument;

  UserDocument(String email) {
    userDocument = getUserDocument(email);
  }

  DocumentReference getUserDocument(String email) {
    return firestore.collection('Users').doc(email);
  }

  Stream<DocumentSnapshot> getUserDocumentSnapshots() {
    return userDocument.snapshots();
  }

  Stream getUsername(Stream<DocumentSnapshot> userDocumentSnapshots) {
    return userDocumentSnapshots.map((snapshot) {
      if (snapshot.exists) {
        return snapshot['username'];
      }

      return null;
    }).distinct();
  }
}
