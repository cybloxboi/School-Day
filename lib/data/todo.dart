import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_day/data/time.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum Priority {
  low,
  medium,
  high,
}

enum SortOption {
  createdTime,
  priority,
  dueDate,
}

extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.createdTime:
        return 'วันที่สร้าง';
      case SortOption.priority:
        return 'ความสำคัญ';
      case SortOption.dueDate:
        return 'วันครบกำหนด';
    }
  }

  String get key => name;
}

Future<void> saveSortOption(SortOption option) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('sortOption', option.key);
}

Future<SortOption> loadSortOption() async {
  final prefs = await SharedPreferences.getInstance();
  final key = prefs.getString('sortOption');

  return SortOption.values.firstWhere(
    (e) => e.key == key,
    orElse: () => SortOption.createdTime,
  );
}

extension PriorityExtension on Priority {
  String toLocalizedString() {
    switch (this) {
      case Priority.low:
        return 'น้อย';
      case Priority.medium:
        return 'กลาง';
      case Priority.high:
        return 'มาก';
    }
  }
}

class Todo {
  String id;
  Priority? priority;
  String title;
  String? description;
  bool isDone;
  late final Timestamp createdTime;
  DateTime? selectedDate;
  Time? alarmTime;
  final String? categoryName;

  static const Uuid _uuid = Uuid();

  Todo({
    String? id,
    required this.title,
    this.priority,
    this.description,
    this.selectedDate,
    this.alarmTime,
    this.categoryName,
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
      selectedDate: json['selectedDate'] != null
          ? DateTime.tryParse(json['selectedDate'])
          : null,
      alarmTime:
          json['alarmTime'] != null ? Time.fromJson(json['alarmTime']) : null,
      priority: json['priority'] != null
          ? Priority.values.firstWhere(
              (e) => e.name == json['priority'],
              orElse: () => Priority.low,
            )
          : null,
      createdTime: switch (json['createdTime']) {
        final Timestamp t => t,
        final int millis => Timestamp.fromMillisecondsSinceEpoch(millis),
        final String s =>
          Timestamp.fromDate(DateTime.tryParse(s) ?? DateTime.now()),
        _ => Timestamp.now(),
      },
      isDone: json['isDone'] is bool ? json['isDone'] : false,
      categoryName: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'selectedDate': selectedDate?.toIso8601String(),
      'alarmTime': alarmTime?.toJson(),
      'priority': priority?.name,
      'createdTime': createdTime,
      'isDone': isDone,
      'name': categoryName,
    };
  }

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? selectedDate,
    Time? alarmTime,
    Priority? priority,
    bool? isDone,
    Timestamp? createdTime,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      selectedDate: selectedDate ?? this.selectedDate,
      alarmTime: alarmTime ?? this.alarmTime,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      createdTime: createdTime ?? this.createdTime,
    );
  }
}
