import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_day/services/timetable_database/timetable_document.dart';

class TimetableSetInfo {
  final String id;
  final String name;

  TimetableSetInfo({required this.id, required this.name});
}

class TimetableSetDocument extends TimetableDocument {
  TimetableSetDocument({
    required super.email,
  });

  Stream<List<TimetableSetInfo>> fetchTimetableSets() {
    return timetableCol.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TimetableSetInfo(
          id: doc.id,
          name: doc['name'] as String,
        );
      }).toList();
    });
  }

  Future<void> createNewTimetableSet({
    required String name,
  }) async {
    DocumentReference newTimetableDoc = getUserTimetableDoc();

    try {
      // Write
      await newTimetableDoc.set({
        'name': name,
        'createdAt': Timestamp.now(),
        'days': allDaysData,
      });
    } catch (e) {
      return;
    }
  }

  Future<void> deleteTimetableSet({
    required String timetableID,
  }) async {
    DocumentReference timetableDoc = getUserTimetableDoc(timetableID);

    try {
      // Delete
      await timetableDoc.delete();
    } catch (e) {
      return;
    }
  }

  Future<void> updateTimetableSet({
    required String timetableID,
    required String name,
  }) async {
    DocumentReference timetableDoc = getUserTimetableDoc(timetableID);

    try {
      // Write
      timetableDoc.update({
        'name': name,
      });
    } catch (e) {
      return;
    }
  }
}
