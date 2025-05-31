import 'package:flutter/material.dart';
import 'package:school_day/data/time.dart';
import 'package:school_day/styles/styles.dart';

class SubjectsGrid extends StatelessWidget {
  SubjectsGrid({
    super.key,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.professor,
  });

  final String title;
  final Time startTime;
  final Time endTime;
  final String location;
  final String professor;
  final DateTime now = DateTime.now();

  @override
  Widget build(BuildContext context) {
    DateTime startTimeToDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      startTime.hour,
      startTime.minute,
    );
    Duration remaining = startTimeToDateTime.difference(now);

    String remainingText;

    if (remaining.isNegative) {
      remainingText = 'เริ่มไปแล้ว';
    } else {
      remainingText = 'อีก ';

      if (remaining.inHours > 0) {
        remainingText += '${remaining.inHours} ชม.';
      }

      remainingText += '${remaining.inMinutes % 60} นาที';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 18.0,
          vertical: 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                Text(
                  remainingText,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time, size: 24, color: primaryColor),
                const SizedBox(width: 10),
                Text(
                  startTime.toString(),
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.chevron_right_rounded),
                Text(
                  endTime.toString(),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person, size: 24, color: primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    professor,
                    style: const TextStyle(fontSize: 16),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.location_city_rounded,
                  size: 24,
                  color: primaryColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(fontSize: 16),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
