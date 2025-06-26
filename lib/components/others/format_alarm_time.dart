import 'package:intl/intl.dart';

String formatAlarmTime(String? rawAlarmTime) {
  if (rawAlarmTime == null || rawAlarmTime.isEmpty || rawAlarmTime == 'ไม่มี') {
    return 'ไม่มี';
  }

  try {
    DateTime alarmDateTime = DateTime.parse(rawAlarmTime).toLocal();

    final thaiDateFormat = DateFormat("d MMM y", 'th_TH');

    final buddhistYear = alarmDateTime.year + 543;
    final formattedDate = thaiDateFormat
        .format(alarmDateTime)
        .replaceAll('${alarmDateTime.year}', '$buddhistYear');

    return formattedDate;
  } catch (e) {
    return 'รูปแบบเวลาไม่ถูกต้อง';
  }
}
