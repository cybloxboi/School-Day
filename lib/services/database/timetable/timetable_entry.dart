import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:school_day/data/timetable.dart';
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

      await _updateTodaySlots(selectedDayIndex);
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

      await _updateTodaySlots(dayIndex);
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

      await _updateTodaySlots(dayIndex);
      await _updateTodaySlots(newDayIndex);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _updateTodaySlots(int dayIndex) async {
    final now = DateTime.now().toLocal();
    final currentDayIndex = (now.weekday + 6) % 7;

    if (currentDayIndex != dayIndex) return;

    final snapshot = await timetableDoc.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final days = data['days'] as Map<String, dynamic>?;
    if (days == null) return;

    final todayLessonsRaw = days[currentDayIndex.toString()] ?? [];
    final todaySlots = List<Map<String, dynamic>>.from(todayLessonsRaw);

    final nowMinutes = now.hour * 60 + now.minute;

    final notifySlots = todaySlots.where((slot) {
      return slot['isNotify'] == true;
    }).toList();

    final notifyTargets = notifySlots
        .map((slot) {
          final startTime = slot['startTime'] as Map<String, dynamic>;
          final notifyTime = slot['notifyTime'] as Map<String, dynamic>;

          final startMinutes =
              (startTime['hour'] ?? 0) * 60 + (startTime['minute'] ?? 0);
          final notifyAtMinutes =
              (notifyTime['hour'] ?? 0) * 60 + (notifyTime['minute'] ?? 0);

          return startMinutes - notifyAtMinutes;
        })
        .where((targetMinutes) => targetMinutes >= nowMinutes) // เฉพาะอนาคต
        .toList();

    final hasTodayNotification = notifyTargets.isNotEmpty;
    final nextNotificationMinutes = hasTodayNotification
        ? notifyTargets.reduce((a, b) => a < b ? a : b)
        : null;

    await FirebaseFirestore.instance.collection('Users').doc(email).set({
      'todaySlots': todaySlots,
      'hasTodayNotification': hasTodayNotification,
      'nextNotificationMinutes': nextNotificationMinutes,
    }, SetOptions(merge: true));
  }
}
