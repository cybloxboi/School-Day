import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:school_day/data/time.dart';
import 'package:school_day/data/timetable.dart';
import 'package:school_day/screens/navigation_menu.dart';
import 'package:school_day/services/database/timetable/timetable_entry.dart';
import 'package:school_day/styles/styles.dart';
import 'package:uuid/uuid.dart';

class AddNewTimetablePage extends StatefulWidget {
  const AddNewTimetablePage({
    super.key,
    required this.timetableEntry,
    this.timetableData,
  });

  final TimetableEntry timetableEntry;
  final Timetable? timetableData;

  @override
  State<AddNewTimetablePage> createState() => _AddNewTimetablePageState();
}

class _AddNewTimetablePageState extends State<AddNewTimetablePage> {
  final _formKey = GlobalKey<FormState>();

  final _subjectController = TextEditingController();
  final _locationController = TextEditingController();
  final _professorController = TextEditingController();

  Time _startTime = Time(TimeOfDay.now().hour, 0);
  late Time _endTime;

  late bool isNotify;
  late Time notifyTime;

  late bool isAlarmOn;
  late bool isNotificationOn;

  final List<String> days = [
    'วันจันทร์',
    'วันอังคาร',
    'วันพุธ',
    'วันพฤหัสบดี',
    'วันศุกร์',
    'วันเสาร์',
    'วันอาทิตย์',
  ];

  final Map<String, Time> notificationTimes = {
    'ถึงเวลาเข้าเรียน': Time(0, 0),
    'ก่อน 5 นาที': Time(0, 5),
    'ก่อน 10 นาที': Time(0, 10),
    'ก่อน 15 นาที': Time(0, 15),
    'ก่อน 30 นาที': Time(0, 30),
    'ก่อน 1 ชั่วโมง': Time(1, 0),
  };

  late final List<Time> notificationTimesValues;
  late final List<String> notificationTimesKeys;

  late int selectedDayIndex;
  int selectedNotification = 0;

  @override
  void initState() {
    notificationTimesValues = notificationTimes.values.toList();
    notificationTimesKeys = notificationTimes.keys.toList();

    if (widget.timetableData != null) {
      _subjectController.text = widget.timetableData!.title;
      _locationController.text = widget.timetableData!.location;
      _professorController.text = widget.timetableData!.professor;
      _startTime = widget.timetableData!.startTime;
      _endTime = widget.timetableData!.endTime;
      isNotify = widget.timetableData!.isNotify;
      notifyTime = widget.timetableData!.notifyTime;
      selectedNotification = notificationTimes.entries.toList().indexWhere(
            (entry) =>
                entry.value.hour == notifyTime.hour &&
                entry.value.minute == notifyTime.minute,
          );
    } else {
      isNotify = true;
      notifyTime = Time(0, 0);
      selectedNotification = 0;

      if (_startTime.hour + 1 == 24) {
        _endTime = Time(0, 0);
      } else {
        _endTime = Time(_startTime.hour + 1, 0);
      }
    }

    selectedDayIndex = widget.timetableEntry.dayIndex;

    super.initState();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _locationController.dispose();
    _professorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      widget.timetableData == null
                          ? 'ต้องการยกเลิกสร้างตารางเรียนนี้ใช่ไหม :<'
                          : 'ต้องการยกเลิกการเปลี่ยนแปลงตารางเรียนนี้ใช่ไหม :<',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NavigationMenu(
                              dateIndex: widget.timetableEntry.dayIndex,
                              screenIndex: 1,
                            ),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: const Text('ยกเลิก'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('แก้ไขต่อ'),
                    ),
                  ],
                );
              },
            );
          },
        ),
        centerTitle: false,
        title: Text(
          widget.timetableData == null
              ? 'เพิ่มตารางเรียนใหม่'
              : 'แก้ไขตารางเรียน',
          style: textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (_startTime.hour == _endTime.hour &&
                      _startTime.minute == _endTime.minute) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'เวลาเริ่มเรียน กับเวลาเลิกเรียนตรงกันไม่ได้นะคับ :(',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  if (!isNotify) {
                    notifyTime = Time(0, 0);
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Center(
                      child: LoadingAnimationWidget.fourRotatingDots(
                        color: primaryColor,
                        size: 80,
                      ),
                    ),
                  );

                  Timetable newLesson = Timetable(
                    title: _subjectController.text.trim(),
                    professor: _professorController.text.trim(),
                    location: _locationController.text.trim(),
                    startTime: _startTime,
                    endTime: _endTime,
                    isNotify: isNotify,
                    notifyTime: notifyTime,
                  );
                  newLesson.id = widget.timetableData?.id ?? const Uuid().v4();

                  bool success;

                  if (widget.timetableData != null) {
                    success = await widget.timetableEntry.updateLesson(
                      newDayIndex: selectedDayIndex,
                      oldLesson: widget.timetableData!,
                      updatedLesson: newLesson,
                    );
                  } else {
                    success = await widget.timetableEntry.addLesson(
                      selectedDayIndex: selectedDayIndex,
                      newLesson: newLesson,
                    );
                  }

                  if (!context.mounted) return;

                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NavigationMenu(
                        dateIndex: selectedDayIndex,
                        screenIndex: 1,
                      ),
                    ),
                    (Route<dynamic> route) => false,
                  );

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          widget.timetableData == null
                              ? 'เพิ่มตารางเรียนเรียบร้อยคับ!'
                              : 'แก้ไขตารางเรียนเรียบร้อย',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          widget.timetableData == null
                              ? 'ดูเหมือนจะมีปัญหาการเพิ่มตารางเรียนนะ :('
                              : 'ดูเหมือนจะมีปัญหาการแก้ไขตารางเรียนนะ :(',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('บันทึก'),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 32),
                  child: Form(
                    key: _formKey,
                    child: Center(
                      child: Column(
                        spacing: 50,
                        children: [
                          Wrap(
                            spacing: 16,
                            runSpacing: 32,
                            children: [
                              textField(_subjectController, 'ชื่อวิชา',
                                  Icons.book_rounded, 615),
                              textField(_locationController, 'สถานที่',
                                  Icons.location_city_rounded, 300),
                              textField(_professorController, 'ผู้สอน',
                                  Icons.person_rounded, 300),
                            ],
                          ),
                          const Divider(),
                          Wrap(
                            runSpacing: 32,
                            spacing: 32,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 600),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.date_range_rounded),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        'วันที่เรียน',
                                        softWrap: true,
                                        style: textTheme.bodyMedium!.copyWith(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text(
                                                'เลือกวันที่เรียน',
                                                style: textTheme.bodyMedium!
                                                    .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: SingleChildScrollView(
                                                child: Column(
                                                  children: List.generate(
                                                    days.length,
                                                    (index) {
                                                      return RadioListTile(
                                                        title:
                                                            Text(days[index]),
                                                        value: index,
                                                        groupValue:
                                                            selectedDayIndex,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            selectedDayIndex =
                                                                value!;
                                                          });
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      child: Text(
                                        days[selectedDayIndex],
                                        style: textTheme.bodyMedium!.copyWith(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 600),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.schedule_rounded),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        'เวลาเรียน',
                                        softWrap: true,
                                        style: textTheme.bodyMedium!.copyWith(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () async {
                                        final TimeOfDay? time =
                                            await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay(
                                            hour: _startTime.hour,
                                            minute: _startTime.minute,
                                          ),
                                          cancelText: 'ยกเลิก',
                                          confirmText: 'ตกลง',
                                          hourLabelText: 'ชั่วโมง',
                                          minuteLabelText: 'นาที',
                                          helpText: 'เลือกเวลาเข้าเรียน',
                                          builder: (BuildContext context,
                                              Widget? child) {
                                            return MediaQuery(
                                              data: MediaQuery.of(context)
                                                  .copyWith(
                                                alwaysUse24HourFormat: true,
                                                textScaler:
                                                    const TextScaler.linear(1),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );

                                        setState(() {
                                          if (time == null) {
                                            return;
                                          }

                                          _startTime = Time(
                                            time.hour,
                                            time.minute,
                                          );
                                        });
                                      },
                                      child: Text(
                                        _startTime.toString(),
                                        style: textTheme.bodyMedium!.copyWith(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right_rounded),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () async {
                                        final TimeOfDay? time =
                                            await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay(
                                            hour: _endTime.hour,
                                            minute: _endTime.minute,
                                          ),
                                          cancelText: 'ยกเลิก',
                                          confirmText: 'ตกลง',
                                          hourLabelText: 'ชั่วโมง',
                                          minuteLabelText: 'นาที',
                                          helpText: 'เลือกเวลาเลิกเรียน',
                                          builder: (BuildContext context,
                                              Widget? child) {
                                            return MediaQuery(
                                              data: MediaQuery.of(context)
                                                  .copyWith(
                                                alwaysUse24HourFormat: true,
                                                textScaler:
                                                    const TextScaler.linear(1),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );

                                        setState(() {
                                          if (time == null) {
                                            return;
                                          }

                                          _endTime = Time(
                                            time.hour,
                                            time.minute,
                                          );
                                        });
                                      },
                                      child: Text(
                                        _endTime.toString(),
                                        style: textTheme.bodyMedium!.copyWith(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Wrap(
                                spacing: 32,
                                runSpacing: 32,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                runAlignment: WrapAlignment.center,
                                children: [
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 600),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        const Icon(
                                            Icons.notifications_outlined),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            'แจ้งเตือนเวลาเข้าเรียน',
                                            softWrap: true,
                                            style: textTheme.bodyMedium!
                                                .copyWith(fontSize: 16),
                                          ),
                                        ),
                                        const Spacer(),
                                        Switch(
                                          value: isNotify,
                                          onChanged: (value) {
                                            setState(() {
                                              isNotify = value;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isNotify)
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 600,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'แจ้งเตือนเมื่อ',
                                            style:
                                                textTheme.bodyMedium!.copyWith(
                                              fontSize: 16,
                                            ),
                                          ),
                                          const Spacer(),
                                          TextButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Text(
                                                      'เลือกเวลาแจ้งเตือน',
                                                      style: textTheme
                                                          .bodyMedium!
                                                          .copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    content:
                                                        SingleChildScrollView(
                                                      child: Column(
                                                        children: List.generate(
                                                          notificationTimes
                                                              .length,
                                                          (index) {
                                                            return RadioListTile(
                                                              title: Text(
                                                                notificationTimesKeys[
                                                                    index],
                                                              ),
                                                              value: index,
                                                              groupValue:
                                                                  selectedNotification,
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  selectedNotification =
                                                                      value!;

                                                                  notifyTime =
                                                                      notificationTimesValues[
                                                                          value];
                                                                });
                                                                Navigator.pop(
                                                                  context,
                                                                );
                                                              },
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            child: Text(
                                              notificationTimesKeys[
                                                  selectedNotification],
                                              style: textTheme.bodyMedium!
                                                  .copyWith(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.timetableData != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width * 0.5,
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  child: FilledButton.icon(
                    onPressed: () async {
                      bool? confirmDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            content: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('คุณต้องการลบตารางเรียนใช่ไหม :<'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                                child: const Text('ยกเลิก'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                child: const Text('ลบ'),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmDelete != true || !context.mounted) return;

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Center(
                          child: LoadingAnimationWidget.fourRotatingDots(
                            color: primaryColor,
                            size: 80,
                          ),
                        ),
                      );

                      bool success = await widget.timetableEntry.deleteLesson(
                        lesson: widget.timetableData!,
                      );

                      if (!context.mounted) return;

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NavigationMenu(
                            dateIndex: selectedDayIndex,
                            screenIndex: 1,
                          ),
                        ),
                        (Route<dynamic> route) => false,
                      );

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ลบตารางเรียนเรียบร้อย!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'ดูเหมือนจะมีปัญหาการลบตารางเรียนนะ :(',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'ลบตารางเรียน',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget textField(
    TextEditingController controller,
    String hintText,
    IconData icon,
    double maxWidth,
  ) {
    return LayoutBuilder(builder: (context, snapshot) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: snapshot.maxWidth > 650 ? maxWidth : snapshot.maxWidth,
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                ),
                maxLength: 50,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'โปรดกรอก$hintTextด้วยนะงับ';
                  }

                  return null;
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}
