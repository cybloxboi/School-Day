import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserDocument {
  final firestore = FirebaseFirestore.instance;

  late DocumentReference userDocument;
  late String email;

  UserDocument(this.email) {
    userDocument = getUserDocument();
  }

  DocumentReference getUserDocument() {
    return firestore.collection('Users').doc(email);
  }

  Future<void> updateIsNotifyTimetable(bool value) async {
    await userDocument.update({'isNotifyTimetable': value});
  }

  Future<void> updateUsername(String newUsername) async {
    await userDocument.update({'username': newUsername});
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

  Stream getIsNotifyTimetable(Stream<DocumentSnapshot> userDocumentSnapshots) {
    return userDocumentSnapshots.map((snapshot) {
      if (snapshot.exists) {
        return snapshot['isNotifyTimetable'];
      }

      return null;
    }).distinct();
  }

  Future<void> createUserDocument({
    required String username,
  }) async {
    final Map<String, dynamic> allDaysData = {
      "0": [],
      "1": [],
      "2": [],
      "3": [],
      "4": [],
      "5": [],
      "6": [],
    };

    try {
      CollectionReference timetableCol = userDocument.collection('Timetables');
      DocumentReference timetableDoc = timetableCol.doc();
      String timetableID = timetableDoc.id;

      CollectionReference todosCol = userDocument.collection('Todos');
      DocumentReference defaultCategoryDoc = todosCol.doc();
      String defaultCategoryID = defaultCategoryDoc.id;

      // Write
      await userDocument.set({
        'email': email,
        'username': username,
        'createdAt': Timestamp.now(),
        'currentTimetableID': timetableID,
        'currentCategoryID': defaultCategoryID,
        'todaySlots': [],
        'hasTodayNotification': false,
        'isNotifyTimetable': true,
        'isNotifyTodos': true,
        'nextNotificationMinutes': null,
      });

      // Write
      await timetableDoc.set({
        'name': 'ตารางเรียนเริ่มต้น',
        'createdAt': Timestamp.now(),
        'days': allDaysData,
      });

      await defaultCategoryDoc.set({
        'name': 'หมวดหมู่งานเริ่มต้น',
        'createdAt': Timestamp.now(),
        'todos': [],
      });
    } catch (e) {
      debugPrint(e.toString());
      return;
    }
  }
}
