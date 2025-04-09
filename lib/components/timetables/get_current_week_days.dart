List<DateTime> getCurrentWeekDays() {
  DateTime now = DateTime.now();
  int currentWeekday = now.weekday;

  DateTime firstDayOfWeek = now.subtract(Duration(days: currentWeekday - 1));

  return List.generate(
    7,
    (index) => firstDayOfWeek.add(
      Duration(days: index),
    ),
  );
}
