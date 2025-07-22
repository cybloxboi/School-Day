class Time {
  final int hour;
  final int minute;

  Time(this.hour, this.minute);

  int toMinutes() => hour * 60 + minute;

  factory Time.fromJson(Map<String, dynamic> json) {
    return Time(json['hour'] as int, json['minute'] as int);
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Time &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;

  Duration timeDifference(Time other) {
    DateTime dateTime1 = DateTime(2025, 3, 2, hour, minute);
    DateTime dateTime2 = DateTime(2025, 3, 2, other.hour, other.minute);

    if (dateTime2.isBefore(dateTime1)) {
      dateTime2 = dateTime2.add(const Duration(days: 1));
    }

    return dateTime2.difference(dateTime1);
  }

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
