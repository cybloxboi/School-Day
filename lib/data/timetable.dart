import 'package:school_day/data/time.dart';
import 'package:uuid/uuid.dart';

class Timetable {
  String title;
  Time startTime;
  Time endTime;
  String location;
  String professor;
  String id;

  static const Uuid _uuid = Uuid();

  Timetable({
    required this.title,
    required this.professor,
    required this.location,
    required this.startTime,
    required this.endTime,
    String? id,
  }) : id = id ?? _uuid.v4();

  factory Timetable.fromJson(Map<String, dynamic> json) {
    return Timetable(
      title: json['title'],
      professor: json['professor'],
      location: json['location'],
      startTime: Time.fromJson(json['startTime']),
      endTime: Time.fromJson(json['endTime']),
      id: json['id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'professor': professor,
      'location': location,
      'startTime': startTime.toJson(),
      'endTime': endTime.toJson(),
      'id': id,
    };
  }
}
