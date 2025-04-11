import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_day/data/timetable.dart';
import 'package:school_day/services/notification/notification_service.dart';
import 'package:school_day/services/database/timetable/timetable_document.dart';

class TimetableEntry extends TimetableDocument {
  int dayIndex;
  String timetableID;

  TimetableEntry({
    required super.email,
    required this.timetableID,
    required this.dayIndex,
  }) {
    timetableDoc = getUserTimetableDoc(timetableID);
  }

  Stream<DocumentSnapshot> getTimetableDocumentSnapshots() {
    return timetableDoc.snapshots();
  }

  Stream fetchLessons(Stream<DocumentSnapshot> timetableDocumentSnapshots) {
    return timetableDocumentSnapshots.map((snapshot) {
      if (!snapshot.exists) return [];

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      List<dynamic> lessonsData = data['days']?[dayIndex.toString()] ?? [];

      List<Timetable> lessons = lessonsData
          .map((lesson) => Timetable.fromJson(lesson as Map<String, dynamic>))
          .toList();

      NotificationService()
          .scheduleWeeklyTimetableNotifications(lessons, dayIndex);

      return lessons;
    }).distinct();
  }

  Future<bool> addLesson({
    required int selectedDayIndex,
    required Timetable newLesson,
  }) async {
    try {
      // Write
      await timetableDoc.update({
        'days.$selectedDayIndex': FieldValue.arrayUnion([newLesson.toJson()]),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteLesson({
    required Timetable lesson,
  }) async {
    try {
      // Write
      await timetableDoc.update({
        'days.$dayIndex': FieldValue.arrayRemove([
          lesson.toJson(),
        ])
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateLesson({
    required int newDayIndex,
    required Timetable oldLesson,
    required Timetable updatedLesson,
  }) async {
    try {
      // Write
      await timetableDoc.update({
        'days.$dayIndex': FieldValue.arrayRemove([
          oldLesson.toJson(),
        ]),
      });

      // Write
      await timetableDoc.update({
        'days.$newDayIndex': FieldValue.arrayUnion([
          updatedLesson.toJson(),
        ]),
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}
