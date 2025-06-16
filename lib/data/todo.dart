import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

enum Priority {
  low,
  medium,
  high,
}

class Todo {
  String id;
  Priority? priority;
  String title;
  String? description;
  bool isDone;
  late final Timestamp createdTime;
  DateTime? alarmTime;

  static const Uuid _uuid = Uuid();

  Todo({
    String? id,
    required this.title,
    this.priority,
    this.description,
    this.alarmTime,
    Timestamp? createdTime,
    bool? isDone,
  })  : id = id ?? _uuid.v4(),
        createdTime = createdTime ?? Timestamp.now(),
        isDone = isDone ?? false;

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] ?? _uuid.v4(),
      title: json['title'] ?? 'ไม่รู้จัก',
      description: json['description'],
      alarmTime:
          json['alarmTime'] != null ? DateTime.parse(json['alarmTime']) : null,
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
      isDone: json['isDone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'alarmTime': alarmTime?.toIso8601String(),
      'priority': priority?.name,
      'createdTime': createdTime,
      'isDone': isDone,
    };
  }
}
