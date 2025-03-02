import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/time.dart';
import '../data/timetable.dart';

Future<Map<int, List<Timetable>>> fetchTimetable(String userEmail) async {
  final firestore = FirebaseFirestore.instance;
  final timetablesRef =
      firestore.collection('Users').doc(userEmail).collection('Timetables');

  Map<int, List<Timetable>> data = {for (var i = 0; i < 7; i++) i: []};

  final querySnapshot = await timetablesRef.get();

  for (var doc in querySnapshot.docs) {
    int dayIndex = _dayNameToIndex(doc.id);

    if (doc.exists && doc.data().containsKey('lessons')) {
      List<dynamic> lessons = doc.data()['lessons'];

      data[dayIndex] =
          lessons.map((lesson) => Timetable.fromJson(lesson)).toList();
    }
  }

  return data;
}

int _dayNameToIndex(String dayName) {
  Map<String, int> dayMap = {
    "monday": 0,
    "tuesday": 1,
    "wednesday": 2,
    "thursday": 3,
    "friday": 4,
    "saturday": 5,
    "sunday": 6,
  };
  return dayMap[dayName.toLowerCase()] ?? 0;
}

Future<bool> addTimetableEntry(
  String userEmail,
  String day,
  String title,
  Time startTime,
  Time endTime,
  String location,
  String professor,
  String id,
) async {
  DocumentReference timetableDoc = FirebaseFirestore.instance
      .collection('Users')
      .doc(userEmail)
      .collection('Timetables')
      .doc(day);

  Map<String, dynamic> newLesson = {
    'title': title,
    'startTime': startTime.toJson(),
    'endTime': endTime.toJson(),
    'location': location,
    'professor': professor,
    'id': id,
  };

  try {
    DocumentSnapshot documentSnapshot = await timetableDoc.get();

    if (!documentSnapshot.exists) {
      await timetableDoc.set({
        'lessons': [newLesson],
      });
    } else {
      await timetableDoc.update({
        'lessons': FieldValue.arrayUnion([newLesson]),
      });
    }

    return true;
  } catch (e) {
    return false;
  }
}

Future<List<Map<String, dynamic>>> getTimetable(
    String userEmail, String day) async {
  try {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userEmail)
        .collection('Timetables')
        .doc(day)
        .get();

    if (doc.exists && doc.data() != null && doc['Lessons'] != null) {
      List<Map<String, dynamic>> lessons =
          List<Map<String, dynamic>>.from(doc['Lessons']);
      return lessons;
    } else {
      return [];
    }
  } catch (e) {
    return [];
  }
}

Future<bool> updateTimetableEntry(
  String userEmail,
  String oldDay,
  String newDay,
  String title,
  Time startTime,
  Time endTime,
  String location,
  String professor,
  String id,
) async {
  try {
    DocumentReference oldDayDoc = FirebaseFirestore.instance
        .collection('Users')
        .doc(userEmail)
        .collection('Timetables')
        .doc(oldDay);

    DocumentReference newDayDoc = FirebaseFirestore.instance
        .collection('Users')
        .doc(userEmail)
        .collection('Timetables')
        .doc(newDay);

    DocumentSnapshot oldDaySnapshot = await oldDayDoc.get();

    if (oldDaySnapshot.exists) {
      List<dynamic> oldLessons = oldDaySnapshot['lessons'] ?? [];
      int lessonIndex = oldLessons.indexWhere((lesson) => lesson['id'] == id);

      if (lessonIndex != -1) {
        Map<String, dynamic> updatedLesson = {
          'title': title,
          'startTime': startTime.toJson(),
          'endTime': endTime.toJson(),
          'location': location,
          'professor': professor,
          'id': id,
        };

        if (oldDay != newDay) {
          oldLessons.removeAt(lessonIndex);
          await oldDayDoc.update({'lessons': oldLessons});

          DocumentSnapshot newDaySnapshot = await newDayDoc.get();

          if (newDaySnapshot.exists) {
            List<dynamic> newLessons = newDaySnapshot['lessons'] ?? [];
            newLessons.add(updatedLesson);
            await newDayDoc.update({'lessons': newLessons});
          } else {
            await newDayDoc.set({
              'lessons': [updatedLesson],
            });
          }
        } else {
          oldLessons[lessonIndex] = updatedLesson;
          await oldDayDoc.update({'lessons': oldLessons});
        }

        return true;
      }
    }

    return false;
  } catch (e) {
    return false;
  }
}

Future<bool> deleteTimetableEntry(
    String userEmail, String day, String id) async {
  try {
    DocumentReference timetableDoc = FirebaseFirestore.instance
        .collection('Users')
        .doc(userEmail)
        .collection('Timetables')
        .doc(day);

    DocumentSnapshot documentSnapshot = await timetableDoc.get();

    if (documentSnapshot.exists) {
      List<dynamic> lessons = documentSnapshot['lessons'] ?? [];
      var lessonToRemove = lessons.firstWhere((lesson) => lesson['id'] == id,
          orElse: () => null);

      if (lessonToRemove != null) {
        await timetableDoc.update({
          'lessons': FieldValue.arrayRemove([lessonToRemove])
        });

        return true;
      }

      return false;
    }

    return false;
  } catch (e) {
    return false;
  }
}
