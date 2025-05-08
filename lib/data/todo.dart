import 'package:school_day/data/time.dart';
import 'package:uuid/uuid.dart';

enum Priority {
  low,
  medium,
  high,
}

class Todo {
  String id;
  String category;
  Priority? priority;
  String title;
  String? description;
  Time? alarmTime;

  static const Uuid _uuid = Uuid();

  Todo({
    String? id,
    required this.category,
    required this.title,
    this.priority,
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
      priority: json['priority'] != null
          ? Priority.values.firstWhere(
              (e) => e.name == json['priority'],
              orElse: () => Priority.low,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'description': description,
      'alarmTime': alarmTime?.toJson(),
      'priority': priority?.name,
    };
  }
}
