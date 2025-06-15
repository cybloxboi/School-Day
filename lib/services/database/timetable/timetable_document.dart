import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableDocument {
  final firestore = FirebaseFirestore.instance;

  late DocumentReference userDoc;
  late CollectionReference timetableCol;
  late DocumentReference timetableDoc;

  final String email;

  DocumentReference getUserDocument(String email) {
    return firestore.collection('Users').doc(email);
  }

  CollectionReference getUserTimetablesCollection(
    DocumentReference userDocument,
  ) {
    return userDocument.collection('Timetables');
  }

  DocumentReference getUserTimetableDoc([String? path]) {
    return timetableCol.doc(path);
  }

  TimetableDocument({
    required this.email,
  }) {
    userDoc = getUserDocument(email);
    timetableCol = getUserTimetablesCollection(userDoc);
    timetableDoc = getUserTimetableDoc();
  }

  Stream<DocumentSnapshot> getUserDocumentSnapshots() {
    return userDoc.snapshots();
  }

  Stream getCurrentTimetableID(Stream<DocumentSnapshot> userDocumentSnapshot) {
    return userDocumentSnapshot.map((snapshot) {
      if (snapshot.exists) {
        return snapshot['currentTimetableID'];
      } else {
        return null;
      }
    }).distinct();
  }

  Future<void> updateCurrentTimetableID(String timetableID) async {
    try {
      await userDoc.update({'currentTimetableID': timetableID});
    } catch (e) {
      return;
    }
  }
}
