import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../data/time.dart';
import '../data/timetable.dart';

Future<void> createFirstTimetable(String userEmail,
    [String? timetableID]) async {
  final firestore = FirebaseFirestore.instance;
  final timetablesRef =
      firestore.collection('Users').doc(userEmail).collection('Timetables');

  timetableID ??= timetablesRef.doc().id;

  Map<String, dynamic> firstTimetable = {
    'name': 'ตารางเรียนเริ่มต้น',
    'createdAt': Timestamp.now(),
  };

  try {
    await timetablesRef.doc(timetableID).set(firstTimetable);

    List<String> days = [
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
      "saturday",
      "sunday"
    ];

    for (String day in days) {
      await timetablesRef.doc(timetableID).collection('Days').doc(day).set({
        'lessons': [],
      });
    }
  } catch (e) {
    return;
  }
}

Future<Map<int, List<Timetable>>> fetchTimetable(
  String userEmail,
  String timetableID,
) async {
  final firestore = FirebaseFirestore.instance;
  final timetablesRef = firestore
      .collection('Users')
      .doc(userEmail)
      .collection('Timetables')
      .doc(timetableID)
      .collection('Days');

  Map<int, List<Timetable>> data = {for (var i = 0; i < 7; i++) i: []};

  final querySnapshot = await timetablesRef.get();

  for (var doc in querySnapshot.docs) {
    int dayIndex = _dayNameToIndex(doc.id);

    if (doc.exists) {
      if (doc.data().containsKey('lessons') && doc.data()['lessons'] != null) {
        List<dynamic> lessons = doc.data()['lessons'];

        data[dayIndex] =
            lessons.map((lesson) => Timetable.fromJson(lesson)).toList();
      } else {
        data[dayIndex] = [];
      }
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
  String timetableID,
  String day,
  String title,
  Time startTime,
  Time endTime,
  String location,
  String professor,
  String id,
  bool isNotify,
  Time notifyTime,
) async {
  DocumentReference timetableDoc = FirebaseFirestore.instance
      .collection('Users')
      .doc(userEmail)
      .collection('Timetables')
      .doc(timetableID)
      .collection('Days')
      .doc(day);

  Map<String, dynamic> newLesson = {
    'title': title,
    'startTime': startTime.toJson(),
    'endTime': endTime.toJson(),
    'location': location,
    'professor': professor,
    'id': id,
    'isNotify': isNotify,
    'notifyTime': notifyTime.toJson(),
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

Future<bool> updateTimetableEntry(
  String userEmail,
  String timetableID,
  String oldDay,
  String newDay,
  String title,
  Time startTime,
  Time endTime,
  String location,
  String professor,
  String id,
  bool isNotify,
  Time notifyTime,
) async {
  try {
    DocumentReference oldDayDoc = FirebaseFirestore.instance
        .collection('Users')
        .doc(userEmail)
        .collection('Timetables')
        .doc(timetableID)
        .collection('Days')
        .doc(oldDay);

    DocumentReference newDayDoc = FirebaseFirestore.instance
        .collection('Users')
        .doc(userEmail)
        .collection('Timetables')
        .doc(timetableID)
        .collection('Days')
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
          'isNotify': isNotify,
          'notifyTime': notifyTime.toJson(),
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
  String userEmail,
  String timetableID,
  String day,
  String id,
) async {
  try {
    DocumentReference timetableDoc = FirebaseFirestore.instance
        .collection('Users')
        .doc(userEmail)
        .collection('Timetables')
        .doc(timetableID)
        .collection('Days')
        .doc(day);

    DocumentSnapshot documentSnapshot = await timetableDoc.get();

    if (documentSnapshot.exists) {
      List<dynamic> lessons = documentSnapshot['lessons'] ?? [];
      var lessonToRemove = lessons.firstWhere(
        (lesson) => lesson['id'] == id,
        orElse: () => null,
      );

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

Future<String?> createTimetable(String userEmail, String timetableName) async {
  try {
    String timetableID = const Uuid().v4();

    DocumentReference timetableRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(userEmail)
        .collection('Timetables')
        .doc(timetableID);

    await timetableRef.set({
      'name': timetableName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return timetableID;
  } catch (e) {
    return null;
  }
}

Future<List<Map<String, String>>> getAllTimetableSets(String userEmail) async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userEmail)
        .collection('Timetables')
        .get();

    List<Map<String, String>> timetables = [];

    for (var doc in querySnapshot.docs) {
      timetables.add({
        'id': doc.id,
        'name': doc['name'],
      });
    }

    return timetables;
  } catch (e) {
    return [];
  }
}

Future<List<String>> fetchTimetableIDs(String userEmail) async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userEmail)
        .collection('Timetables')
        .get();

    List<String> timetableIDs =
        querySnapshot.docs.map((doc) => doc.id).toList();

    return timetableIDs;
  } catch (e) {
    return [];
  }
}

Future<void> updateCurrentTimetableID(
  String userEmail,
  String newTimetableID,
) async {
  await FirebaseFirestore.instance
      .collection('Users')
      .doc(userEmail)
      .update({'currentTimetableID': newTimetableID});
}

Future<String?> getCurrentTimetableID(String userEmail) async {
  try {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userEmail)
        .get();

    if (userDoc.exists && userDoc.data() != null) {
      return userDoc['currentTimetableID'] as String?;
    }

    return null;
  } catch (e) {
    return null;
  }
}
