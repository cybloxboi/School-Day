import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_day/services/database/timetable/timetable_document.dart';

class TimetableSetInfo {
  final String id;
  final String name;

  TimetableSetInfo({required this.id, required this.name});

  factory TimetableSetInfo.fromFirestore(DocumentSnapshot doc) {
    return TimetableSetInfo(
      id: doc.id,
      name: doc['name'] ?? 'ไม่มีชื่อ',
    );
  }
}

class TimetableSetDocument extends TimetableDocument {
  TimetableSetDocument({
    required super.email,
  });

  Stream<QuerySnapshot> getTimetableSetQuerySnapshots() {
    return timetableCol.snapshots();
  }

  Stream<List<TimetableSetInfo>> fetchTimetableSets(
    Stream<QuerySnapshot> timetableQuerySnapshots,
  ) {
    return timetableQuerySnapshots.map((snapshot) {
      return snapshot.docs.map((doc) {
        return TimetableSetInfo(
          id: doc.id,
          name: doc['name'] as String,
        );
      }).toList();
    }).distinct();
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
