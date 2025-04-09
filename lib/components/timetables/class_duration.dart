import 'package:flutter/material.dart';
import 'package:school_day/data/time.dart';
import 'package:school_day/styles/styles.dart';

Text classDuration(Time startTime, Time endTime) {
  Duration difference = startTime.timeDifference(endTime);
  String text = '';

  if (difference.inHours >= 1) {
    text += '${difference.inHours} ชม.';
  }

  if (difference.inMinutes % 60 != 0) {
    if (text.isNotEmpty) {
      text += ' ';
    }

    text += '${difference.inMinutes % 60} นาที';
  }

  return Text(
    text,
    style: textTheme.bodySmall,
  );
}
