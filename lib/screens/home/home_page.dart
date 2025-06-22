import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:school_day/components/home/subjects_grid.dart';
import 'package:school_day/components/home/tasks_grid.dart';
import 'package:school_day/components/home/welcome_text.dart';
import 'package:school_day/components/others/check_latest_profile_image.dart';
import 'package:school_day/data/timetable.dart';
import 'package:school_day/data/todo.dart';
import 'package:school_day/screens/ai/chat_page.dart';
import 'package:school_day/services/database/timetable/timetable_entry.dart';
import 'package:school_day/services/database/timetable/timetable_set.dart';
import 'package:school_day/services/database/todo/get_today_todos_stream.dart';
import 'package:school_day/services/database/todo/todo_entry.dart';
import 'package:school_day/services/database/user/user_document.dart';
import 'package:school_day/styles/styles.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime now = DateTime.now();
  late String today;
  late UserDocument userDocument;
  late final Stream<DocumentSnapshot> _userStream;
  late final TimetableSetDocument timetableSet;
  late final Stream _timetableIDStream;
  late int dateIndex;
  late User? currentUser;

  String greetingText = 'สวัสดี!';

  int selectedPageIndex = 0;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    userDocument = UserDocument(currentUser!.email!);
    _userStream = userDocument.getUserDocumentSnapshots();
    today = '${DateFormat('d MMM').format(now)} ${now.year + 543}';
    timetableSet = TimetableSetDocument(email: currentUser!.email!);
    _timetableIDStream = timetableSet.getCurrentTimetableID(_userStream);
    dateIndex = DateTime.now().weekday - 1;

    updateProfileImageUrl(currentUser!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'หน้าแรก',
          style: textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatPage(),
                ),
              ),
              icon: const Icon(Icons.try_sms_star_rounded),
              label: Text(
                'AI',
                style: textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                expandedHeight: 230,
                backgroundColor: backgroundColor,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 20,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StreamBuilder(
                              stream: userDocument.getUsername(_userStream),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  greetingText = 'สวัสดี, ${snapshot.data}!';
                                }

                                return Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 8,
                                    children: [
                                      AnimatedTextKit(
                                        key: ValueKey(snapshot.data),
                                        isRepeatingAnimation: false,
                                        totalRepeatCount: 1,
                                        animatedTexts: [
                                          TypewriterAnimatedText(
                                            greetingText,
                                            textStyle:
                                                textTheme.bodySmall!.copyWith(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            speed: const Duration(
                                              milliseconds: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                      DefaultTextStyle(
                                        style: textTheme.bodySmall!.copyWith(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        child: const WelcomeText(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Center(
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: ClipOval(
                                    child: CircleAvatar(
                                      radius: 64,
                                      child: currentUser!.photoURL != null
                                          ? CachedNetworkImage(
                                              imageUrl: currentUser!.photoURL!,
                                              placeholder: (context, url) {
                                                return LoadingAnimationWidget
                                                    .beat(
                                                  color: primaryColor,
                                                  size: 100,
                                                );
                                              },
                                              errorWidget:
                                                  (context, url, error) {
                                                return Image.asset(
                                                  'assets/images/blank_profile.jpg',
                                                );
                                              },
                                            )
                                          : Image.asset(
                                              'assets/images/blank_profile.jpg'),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'วันนี้',
                                  style: textTheme.bodySmall!.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  child: VerticalDivider(
                                    thickness: 2,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  today,
                                  style: textTheme.bodySmall!.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  height: 50,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: ToggleButtons(
                                    borderWidth: 2,
                                    borderColor: Colors.transparent,
                                    selectedBorderColor: Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                    fillColor:
                                        Colors.pink.withValues(alpha: 0.2),
                                    selectedColor: Colors.pink,
                                    color: Colors.black,
                                    isSelected: [
                                      selectedPageIndex == 0,
                                      selectedPageIndex == 1
                                    ],
                                    onPressed: (int index) {
                                      setState(() => selectedPageIndex = index);
                                    },
                                    children: const [
                                      Text('วิชา'),
                                      Text('งาน'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 20),
                sliver: StreamBuilder(
                  stream: _timetableIDStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: LoadingAnimationWidget.fourRotatingDots(
                            color: primaryColor,
                            size: 80,
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(
                            child: Text('เกิดข้อผิดพลาด: ${snapshot.error}')),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(child: Text('ไม่พบ currentTimetableId')),
                      );
                    }

                    if (selectedPageIndex == 0) {
                      TimetableEntry? timetableEntry = selectedPageIndex != 0
                          ? null
                          : TimetableEntry(
                              email: currentUser!.email!,
                              timetableID: snapshot.data!,
                              dayIndex: dateIndex,
                            );

                      return StreamBuilder(
                        stream: timetableEntry?.fetchLessons(
                          timetableEntry.getTimetableDocumentSnapshots(),
                        ),
                        builder: (context, entrySnapshot) {
                          if (entrySnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return SliverToBoxAdapter(
                              child: Center(
                                child: LoadingAnimationWidget.fourRotatingDots(
                                  color: primaryColor,
                                  size: 80,
                                ),
                              ),
                            );
                          }

                          if (entrySnapshot.hasError) {
                            return SliverToBoxAdapter(
                              child: Center(
                                child: Text('Error: ${snapshot.error}'),
                              ),
                            );
                          }

                          List<Timetable> timetableData = entrySnapshot.data!;

                          if (timetableData.isEmpty) {
                            return SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 16,
                                    children: [
                                      Text(
                                        'ไม่มีตารางเรียนสำหรับวันนี้ :>',
                                        softWrap: true,
                                        textAlign: TextAlign.center,
                                        style: textTheme.bodyMedium!.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 30,
                                        ),
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

                          timetableData.sort((a, b) {
                            int rank(Timetable entry) {
                              final start = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                  entry.startTime.hour,
                                  entry.startTime.minute);
                              final end = DateTime(now.year, now.month, now.day,
                                  entry.endTime.hour, entry.endTime.minute);

                              if (now.isAfter(start) && now.isBefore(end)) {
                                return 0; // กำลังเรียนอยู่
                              } else if (now.isBefore(start)) {
                                return 1; // ยังไม่เริ่ม
                              } else {
                                return 2; // เรียนจบแล้ว
                              }
                            }

                            final rankA = rank(a);
                            final rankB = rank(b);

                            if (rankA != rankB) {
                              return rankA.compareTo(rankB);
                            }

                            final aStart = DateTime(now.year, now.month,
                                now.day, a.startTime.hour, a.startTime.minute);
                            final bStart = DateTime(now.year, now.month,
                                now.day, b.startTime.hour, b.startTime.minute);

                            return aStart.compareTo(bStart);
                          });

                          return SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 800,
                              mainAxisExtent: 200,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              childCount: timetableData.length,
                              (BuildContext context, int index) {
                                final details = timetableData[index];

                                return SubjectsGrid(
                                  title: details.title,
                                  startTime: details.startTime,
                                  endTime: details.endTime,
                                  location: details.location,
                                  professor: details.professor,
                                );
                              },
                            ),
                          );
                        },
                      );
                    } else {
                      return StreamBuilder<List<Todo>>(
                        stream: getTodayTodosStream(currentUser!.email!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return SliverToBoxAdapter(
                              child: Center(
                                child: LoadingAnimationWidget.fourRotatingDots(
                                  color: primaryColor,
                                  size: 80,
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return SliverToBoxAdapter(
                              child: Center(
                                child: Text(
                                  'เกิดข้อผิดพลาด: ${snapshot.error}',
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    spacing: 16,
                                    children: [
                                      Text(
                                        'ไม่มีงานสำหรับวันนี้ :>',
                                        softWrap: true,
                                        textAlign: TextAlign.center,
                                        style: textTheme.bodyMedium!.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 30,
                                        ),
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

                          final todayTodos = snapshot.data!;

                          return SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 800,
                              mainAxisExtent: 270,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              childCount: todayTodos.length,
                              (BuildContext context, int index) {
                                return TasksGrid(
                                  todoData: todayTodos[index],
                                );
                              },
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<User?> getCurrentUser() async {
    await FirebaseAuth.instance.currentUser?.reload();
    return FirebaseAuth.instance.currentUser;
  }
}
