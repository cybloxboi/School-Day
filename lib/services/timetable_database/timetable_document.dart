import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableDocument {
  final firestore = FirebaseFirestore.instance;

  late DocumentReference userDoc;
  late CollectionReference timetableCol;
  late DocumentReference timetableDoc;

  final String email;
  final Map<String, dynamic> allDaysData = {
    "0": [],
    "1": [],
    "2": [],
    "3": [],
    "4": [],
    "5": [],
    "6": [],
  };

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

  Stream<String?> getCurrentTimetableID() {
    return firestore.collection('Users').doc(email).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot['currentTimetableID'];
      } else {
        return null;
      }
    });
  }

  Future<void> updateCurrentTimetableID(String timetableID) async {
    try {
      await userDoc.update({'currentTimetableID': timetableID});
    } catch (e) {
      return;
    }
  }

  Future<void> createUserDocument({
    required String username,
  }) async {
    try {
      CollectionReference timetableCol = getUserTimetablesCollection(userDoc);
      DocumentReference timetableDoc = timetableCol.doc();
      String timetableID = timetableDoc.id;

      // Write
      await userDoc.set({
        'email': email,
        'username': username,
        'createdAt': Timestamp.now(),
        'currentTimetableID': timetableID,
      });

      // Write
      await timetableDoc.set({
        'name': 'ตารางเรียนเริ่มต้น',
        'createdAt': Timestamp.now(),
        'days': allDaysData,
      });
    } catch (e) {
      return;
    }
  }
}
