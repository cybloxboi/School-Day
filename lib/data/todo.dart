import 'package:school_day/data/time.dart';
import 'package:uuid/uuid.dart';

class Todo {
  String id;
  String category;
  String title;
  String? description;
  Time? alarmTime;

  static const Uuid _uuid = Uuid();

  Todo({
    String? id,
    required this.category,
    required this.title,
    this.description,
    this.alarmTime,
  }) : id = id ?? _uuid.v4();

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] ?? _uuid.v4(),
      category: json['category'] ?? 'เริ่มต้น',
      title: json['title'] ?? 'ไม่รู้จัก',
      description: json['description'],
      alarmTime:
          json['alarmTime'] != null ? Time.fromJson(json['alarmTime']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'description': description,
      'alarmTime': alarmTime?.toJson(),
    };
  }
}
