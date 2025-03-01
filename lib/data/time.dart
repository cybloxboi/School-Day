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

  Duration difference(Time other) {
    return Duration(minutes: (toMinutes() - other.toMinutes()).abs());
  }

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
