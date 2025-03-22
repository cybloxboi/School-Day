import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../data/time.dart';
import '../data/timetable.dart';

Future<void> createUserDocument(UserCredential? userCredential) async {
  final firestore = FirebaseFirestore.instance;

  DocumentReference userDoc = firestore.collection('Users').doc(
        userCredential?.user!.email,
      );

  try {
    await userDoc.set({
      'email': userCredential?.user!.email,
      'createdAt': Timestamp.now(),
      'currentTimetableID': null,
    });

    String timetableID = userDoc.collection('Timetables').doc().id;

    Map<String, dynamic> defaultTimetable = {
      'name': 'ตารางเรียนเริ่มต้น',
      'createdAt': Timestamp.now(),
    };
    await userDoc
        .collection('Timetables')
        .doc(timetableID)
        .set(defaultTimetable);

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
      await userDoc
          .collection('Timetables')
          .doc(timetableID)
          .collection('Days')
          .doc(day)
          .set({
        'lessons': [],
      });
    }

    await userDoc.update({'currentTimetableID': timetableID});
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

Future<bool> createTimetable(String userEmail, String timetableName) async {
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
      await timetableRef.collection('Days').doc(day).set({
        'lessons': [],
      });
    }

    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> updateTimetableName(
  String userEmail,
  String timetableID,
  String newTimetableName,
) async {
  try {
    DocumentReference timetableRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(userEmail)
        .collection('Timetables')
        .doc(timetableID);

    await timetableRef.update({
      'name': newTimetableName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> deleteTimetableSet(String userEmail, String timetableID) async {
  try {
    DocumentReference timetableRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(userEmail)
        .collection('Timetables')
        .doc(timetableID);

    QuerySnapshot daysSnapshot = await timetableRef.collection('Days').get();
    for (DocumentSnapshot doc in daysSnapshot.docs) {
      await doc.reference.delete();
    }

    await timetableRef.delete();

    return true;
  } catch (e) {
    return false;
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
