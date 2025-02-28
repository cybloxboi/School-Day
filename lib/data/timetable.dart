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
}
