import 'package:school_day/data/time.dart';

class Timetable {
  String title;
  Time startTime;
  Time endTime;
  String location;
  String professor;

  Timetable(
    this.title,
    this.professor,
    this.location,
    this.startTime,
    this.endTime,
  );

  factory Timetable.fromJson(Map<String, dynamic> json) {
    return Timetable(
      json['title'],
      json['professor'],
      json['location'],
      Time.fromJson(json['startTime']),
      Time.fromJson(json['endTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'professor': professor,
      'location': location,
      'startTime': startTime.toJson(),
      'endTime': endTime.toJson(),
    };
  }
}
