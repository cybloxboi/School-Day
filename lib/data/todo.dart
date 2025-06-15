import 'package:cloud_firestore/cloud_firestore.dart';
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
  late final Timestamp createdTime;
  Time? alarmTime;

  static const Uuid _uuid = Uuid();

  Todo({
    String? id,
    required this.category,
    required this.title,
    this.priority,
    this.description,
    this.alarmTime,
    Timestamp? createdTime,
  })  : id = id ?? _uuid.v4(),
        createdTime = createdTime ?? Timestamp.now();

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
      createdTime: json['createdTime'] is Timestamp
          ? json['createdTime']
          : (json['createdTime'] != null
              ? Timestamp.fromMillisecondsSinceEpoch(
                  json['createdTime'].millisecondsSinceEpoch)
              : Timestamp.now()),
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
      'createdTime': createdTime,
    };
  }
}
