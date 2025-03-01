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

Future<void> addTimetableEntry(String userEmail, String day, String title,
    Time startTime, Time endTime, String location, String professor) async {
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
  };

  try {
    DocumentSnapshot documentSnapshot = await timetableDoc.get();

    if (!documentSnapshot.exists) {
      await timetableDoc.set({
        'Lessons': [newLesson],
      });
    } else {
      await timetableDoc.update({
        'Lessons': FieldValue.arrayUnion([newLesson]),
      });
    }
  } catch (e) {
    return;
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

Future<void> updateTimetableEntry(
    String userEmail,
    String day,
    int lessonIndex,
    String title,
    Time startTime,
    Time endTime,
    String location,
    String professor) async {
  try {
    DocumentReference timetableDoc = FirebaseFirestore.instance
        .collection('Users')
        .doc(userEmail)
        .collection('Timetables')
        .doc(day);

    DocumentSnapshot documentSnapshot = await timetableDoc.get();

    if (documentSnapshot.exists) {
      List lessons = documentSnapshot['Lessons'] ?? [];

      if (lessonIndex < lessons.length) {
        lessons[lessonIndex] = {
          'title': title,
          'startTime': startTime.toJson(),
          'endTime': endTime.toJson(),
          'location': location,
          'professor': professor,
        };

        await timetableDoc.update({'lessons': lessons});
      }
    } else {
      await timetableDoc.set({
        'Lessons': [
          {
            'title': title,
            'startTime': startTime.toJson(),
            'endTime': endTime.toJson(),
            'location': location,
            'professor': professor,
          }
        ]
      });
    }
  } catch (e) {
    return;
  }
}

Future<void> deleteTimetableEntry(
    String userEmail, String day, int lessonIndex) async {
  try {
    DocumentReference timetableDoc = FirebaseFirestore.instance
        .collection('Users')
        .doc(userEmail)
        .collection('Timetables')
        .doc(day);

    DocumentSnapshot documentSnapshot = await timetableDoc.get();

    if (documentSnapshot.exists) {
      List lessons = documentSnapshot['Lessons'] ?? [];

      if (lessonIndex < lessons.length) {
        lessons.removeAt(lessonIndex);

        await timetableDoc.update({'lessons': lessons});
      }
    }
  } catch (e) {
    return;
  }
}
