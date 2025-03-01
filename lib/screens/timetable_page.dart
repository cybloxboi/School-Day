import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:school_day/data/time.dart';
import 'package:school_day/data/timetable.dart';
import 'package:school_day/screens/login_page.dart';
import 'package:school_day/services/timetable_database.dart';
import 'package:school_day/styles/styles.dart';
import 'package:timeline_tile/timeline_tile.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  int dateIndex = DateTime.now().weekday - 1;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final List<String> daysInAWeek = [
    'จ.',
    'อ.',
    'พ.',
    'พฤ.',
    'ศ.',
    'ส.',
    'อา.',
  ];

  Future logOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ล็อคเอาท์สำเร็จ'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ตารางเรียน',
          style: textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => logOut(context),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                'ล็อคเอาท์',
                style: textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add_rounded),
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range_rounded),
                onPressed: () {
                  setState(() {
                    dateIndex = DateTime.now().weekday - 1;
                  });
                },
                label: Text(
                  'วันนี้',
                  style: textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  spacing: 8,
                  children: List.generate(
                    daysInAWeek.length,
                    (int index) {
                      return Expanded(
                        child: day(
                          daysInAWeek[index],
                          getCurrentWeekDays()[index].day,
                          index,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder(
                  future: fetchTimetable(currentUser!.email!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: LoadingAnimationWidget.fourRotatingDots(
                          color: primaryColor,
                          size: 80,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    Map<int, List<Timetable>> data =
                        snapshot.data ?? {for (var i = 0; i < 7; i++) i: []};

                    return Builder(builder: (context) {
                      if (data[dateIndex]!.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'ไม่มีตารางเรียน :>',
                              softWrap: true,
                              textAlign: TextAlign.center,
                              style: textTheme.headlineLarge,
                            ),
                          ),
                        );
                      }

                      return timeTableList(data[dateIndex]!, context);
                    });
                  },
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget timeTableList(List<Timetable> data, BuildContext context) {
    Map<int, List<Timetable>> timetableMap = {};

    for (var timetable in data) {
      timetableMap
          .putIfAbsent(timetable.startTime.hour, () => [])
          .add(timetable);
    }

    final entries = timetableMap.entries.toList();

    if (MediaQuery.of(context).size.width >= 800) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListView.builder(
          itemCount: entries.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: TimelineTile(
                axis: TimelineAxis.horizontal,
                isFirst: index == 0,
                isLast: index == entries.length - 1,
                beforeLineStyle: const LineStyle(
                  color: secondaryColor,
                ),
                indicatorStyle: const IndicatorStyle(
                  color: primaryColor,
                ),
                endChild: Padding(
                  padding: const EdgeInsets.only(
                    top: 16,
                    right: 16,
                    left: 16,
                  ),
                  child: Column(
                    spacing: 16,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 8,
                        children: [
                          const Icon(Icons.schedule_rounded),
                          Text(
                            '${entries[index].key}:00',
                            style: textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            spacing: 8,
                            children: List.generate(
                              entries[index].value.length,
                              (cardIndex) {
                                return card(entries[index].value[cardIndex]);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 150, minWidth: 150),
            child: TimelineTile(
              isFirst: index == 0,
              isLast: index == entries.length - 1,
              beforeLineStyle: const LineStyle(
                color: secondaryColor,
              ),
              indicatorStyle: const IndicatorStyle(
                color: primaryColor,
              ),
              endChild: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        const Icon(Icons.schedule_rounded),
                        Text(
                          '${entries[index].key}:00',
                          style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    for (var i in entries[index].value) card(i),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget card(Timetable details) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 8,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    details.title,
                    style: textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                ),
                const SizedBox(width: 8),
                classDuration(
                  details.startTime,
                  details.endTime,
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  details.startTime.toString(),
                  style: textTheme.bodySmall,
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                ),
                Text(
                  details.endTime.toString(),
                  style: textTheme.bodySmall,
                ),
              ],
            ),
            Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Icon(
                  Icons.person_rounded,
                  color: primaryColor,
                ),
                Expanded(
                  child: Text(
                    details.professor,
                    style: textTheme.bodySmall,
                    softWrap: true,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.location_city_rounded,
                  color: primaryColor,
                ),
                Expanded(
                  child: Text(
                    details.location,
                    style: textTheme.bodySmall,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget day(String dayName, int date, int index) {
    return Card(
      color: dateIndex == index ? primaryColor : Colors.white,
      child: InkWell(
        onTap: () {
          setState(() {
            dateIndex = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 4,
            children: [
              Text(
                dayName,
                style: textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                date.toString(),
                style: textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Text classDuration(Time startTime, Time endTime) {
    Duration difference = startTime.difference(endTime);
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
}
