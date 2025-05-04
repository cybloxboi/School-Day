import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:school_day/components/timetables/class_duration.dart';
import 'package:school_day/components/timetables/get_current_week_days.dart';
import 'package:school_day/components/timetables/timetable_sets.dart';
import 'package:school_day/data/timetable.dart';
import 'package:school_day/screens/timetables/add_new_timetable_page.dart';
import 'package:school_day/services/database/timetable/timetable_entry.dart';
import 'package:school_day/services/database/timetable/timetable_set.dart';
import 'package:school_day/styles/styles.dart';
import 'package:timeline_tile/timeline_tile.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key, this.dateIndex, required this.userStream});

  final int? dateIndex;
  final Stream<DocumentSnapshot> userStream;

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  late int dateIndex;
  late final User currentUser;
  late final TimetableSetDocument timetableSet;
  late final Stream<QuerySnapshot> _timetableSetStream;
  late String? currentTimetableID;
  bool isLoading = true;

  final List<String> daysInAWeek = [
    'จ.',
    'อ.',
    'พ.',
    'พฤ.',
    'ศ.',
    'ส.',
    'อา.',
  ];

  @override
  void initState() {
    super.initState();
    dateIndex = widget.dateIndex ?? DateTime.now().weekday - 1;
    currentUser = FirebaseAuth.instance.currentUser!;
    timetableSet = TimetableSetDocument(email: currentUser.email!);
    _timetableSetStream = timetableSet.getTimetableSetQuerySnapshots();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ตารางเรียน',
          style: textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              spacing: 4,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.today_rounded),
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
                IconButton(
                  onPressed: () {
                    if (currentTimetableID == null) return;

                    showModalBottomSheet(
                      showDragHandle: !kIsWeb ? true : false,
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.8,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 32,
                              top: 32,
                              right: 32,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (kIsWeb)
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Spacer(),
                                          IconButton.filledTonal(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            icon: const Icon(
                                              Icons.cancel_rounded,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 16,
                                      ),
                                    ],
                                  ),
                                Text(
                                  'เซตตารางเรียน',
                                  style: textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(),
                                const SizedBox(
                                  height: 16,
                                ),
                                Expanded(
                                  child: StreamBuilder(
                                    stream: timetableSet.fetchTimetableSets(
                                      _timetableSetStream,
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                          child: LoadingAnimationWidget
                                              .fourRotatingDots(
                                            color: primaryColor,
                                            size: 80,
                                          ),
                                        );
                                      }

                                      if (snapshot.hasError) {
                                        return Text(
                                          'เกิดข้อผิดพลาด: ${snapshot.error}',
                                        );
                                      }

                                      List<TimetableSetInfo> timetableSets =
                                          snapshot.data!;

                                      timetableSets.sort((a, b) {
                                        if (a.id == currentTimetableID) {
                                          return -1;
                                        }

                                        if (b.id == currentTimetableID) {
                                          return 1;
                                        }

                                        return 0;
                                      });

                                      return TimetableSets(
                                        currentTimetableID: currentTimetableID!,
                                        timetableSets: timetableSets,
                                        timetableSetDocument: timetableSet,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.list_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (currentTimetableID == null) return;

          TimetableEntry timetableEntry = TimetableEntry(
            email: currentUser.email!,
            timetableID: currentTimetableID!,
            dayIndex: dateIndex,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddNewTimetablePage(
                timetableEntry: timetableEntry,
              ),
            ),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: List.generate(
                    daysInAWeek.length,
                    (int index) {
                      return dayCard(
                        daysInAWeek[index],
                        getCurrentWeekDays()[index].day,
                        index,
                        context,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [0.9, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: StreamBuilder(
                    stream: timetableSet.getCurrentTimetableID(
                      widget.userStream,
                    ),
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
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      currentTimetableID = snapshot.data!;

                      TimetableEntry timetableEntry = TimetableEntry(
                        email: currentUser.email!,
                        timetableID: currentTimetableID!,
                        dayIndex: dateIndex,
                      );

                      return StreamBuilder(
                        stream: timetableEntry.fetchLessons(
                          timetableEntry.getTimetableDocumentSnapshots(),
                        ),
                        builder: (_, entrySnapshot) {
                          if (entrySnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: LoadingAnimationWidget.fourRotatingDots(
                                color: primaryColor,
                                size: 80,
                              ),
                            );
                          }

                          if (entrySnapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          List<Timetable> timetableData = entrySnapshot.data!;

                          timetableData.sort(
                            (a, b) =>
                                a.startTime.hour.compareTo(b.startTime.hour),
                          );

                          return Builder(
                            builder: (context) {
                              if (timetableData.isEmpty) {
                                return Center(
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        spacing: 8,
                                        children: [
                                          Text(
                                            'ไม่มีตารางเรียน :>',
                                            softWrap: true,
                                            textAlign: TextAlign.center,
                                            style:
                                                textTheme.bodyMedium!.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 30,
                                            ),
                                          ),
                                          Text(
                                            'คลิกปุ่ม + เพื่อเพิ่มตารางเรียน',
                                            softWrap: true,
                                            style: textTheme.bodySmall,
                                          ),
                                          LottieBuilder.asset(
                                            'assets/animations/empty_timetable.json',
                                            width: 180,
                                            height: 180,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return timetableList(
                                timetableData,
                                context,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.08),
            ],
          ),
        ),
      ),
    );
  }

  Widget timetableList(List<Timetable> data, BuildContext context) {
    Map<int, List<Timetable>> timetableMap = {};

    for (var timetable in data) {
      timetableMap
          .putIfAbsent(timetable.startTime.hour, () => [])
          .add(timetable);
    }

    final entries = timetableMap.entries.toList();

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            left: MediaQuery.of(context).size.width <= 700
                ? 16
                : MediaQuery.of(context).size.width * 0.075,
          ),
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
              padding: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width <= 700
                    ? 16
                    : MediaQuery.of(context).size.width * 0.04,
                16,
                16,
                16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
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
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: const Divider(),
                  ),
                  for (var i in entries[index].value) timetableDetailCard(i),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget timetableDetailCard(Timetable details) {
    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.black),
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      child: InkWell(
        onTap: () {
          if (currentTimetableID == null) return;

          TimetableEntry timetableEntry = TimetableEntry(
            email: currentUser.email!,
            timetableID: currentTimetableID!,
            dayIndex: dateIndex,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddNewTimetablePage(
                timetableEntry: timetableEntry,
                timetableData: details,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
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
                    const SizedBox(
                      width: 32,
                    ),
                    Row(
                      children: [
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
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.person_rounded,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  details.professor,
                                  style: textTheme.bodySmall,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                details.isNotify
                                    ? Icons.notifications_rounded
                                    : Icons.notifications_off,
                                color: details.isNotify
                                    ? primaryColor
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  details.isNotify
                                      ? 'การแจ้งเตือนเปิด'
                                      : 'การแจ้งเตือนปิด',
                                  style: textTheme.bodySmall,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_city_rounded,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget dayCard(String dayName, int date, int index, BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 60,
        maxWidth: 300,
      ),
      child: Card(
        color: dateIndex == index ? primaryColor : Colors.white,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: InkWell(
          onTap: () {
            setState(() {
              dateIndex = index;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
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
      ),
    );
  }
}
