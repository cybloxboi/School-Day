class Time {
  final int hour;
  final int minute;

  Time(this.hour, this.minute);

  int toMinutes() => hour * 60 + minute;

  Duration difference(Time other) {
    return Duration(minutes: (toMinutes() - other.toMinutes()).abs());
  }

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
