import 'package:school_day/data/time.dart';
import 'package:uuid/uuid.dart';

class Timetable {
  String title;
  Time startTime;
  Time endTime;
  String location;
  String professor;
  String id;
  bool isNotify;
  Time? notifyTime;

  static const Uuid _uuid = Uuid();

  Timetable({
    required this.title,
    required this.professor,
    required this.location,
    required this.startTime,
    required this.endTime,
    String? id,
    required this.isNotify,
    this.notifyTime,
  }) : id = id ?? _uuid.v4();

  factory Timetable.fromJson(Map<String, dynamic> json) {
    return Timetable(
      title: json['title'] ?? 'ไม่รู้จัก',
      professor: json['professor'] ?? 'ไม่รู้จัก',
      location: json['location'] ?? 'ไม่รู้จัก',
      startTime: Time.fromJson(json['startTime'] ?? Time(0, 0)),
      endTime: Time.fromJson(json['endTime'] ?? Time(1, 0)),
      id: json['id'] ?? _uuid.v4(),
      isNotify: json['isNotify'] ?? false,
      notifyTime: json['notifyTime'],
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
      'isNotify': isNotify,
      'notifyTime': notifyTime,
    };
  }
}
