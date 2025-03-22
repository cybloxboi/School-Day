import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:school_day/data/time.dart';
import 'package:school_day/data/timetable.dart';
import 'package:school_day/screens/timetables/timetable_page.dart';
import 'package:school_day/services/notification_service.dart';
import 'package:school_day/services/timetable_database.dart';
import 'package:school_day/styles/styles.dart';
import 'package:uuid/uuid.dart';

class AddNewTimetablePage extends StatefulWidget {
  const AddNewTimetablePage({
    super.key,
    this.timetable,
    this.dateIndex,
    required this.timetableId,
  });

  final Timetable? timetable;
  final String timetableId;
  final int? dateIndex;

  @override
  State<AddNewTimetablePage> createState() => _AddNewTimetablePageState();
}

class _AddNewTimetablePageState extends State<AddNewTimetablePage>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _currentUser = FirebaseAuth.instance.currentUser;

  final _subjectController = TextEditingController();
  final _locationController = TextEditingController();
  final _professorController = TextEditingController();

  Time _startTime = Time(TimeOfDay.now().hour, 0);
  late Time _endTime;

  late bool isNotify;
  late Time notifyTime;

  late bool isAlarmOn;
  late bool isNotificationOn;

  final Map<String, String> days = {
    'monday': 'วันจันทร์',
    'tuesday': 'วันอังคาร',
    'wednesday': 'วันพุธ',
    'thursday': 'วันพฤหัสบดี',
    'friday': 'วันศุกร์',
    'saturday': 'วันเสาร์',
    'sunday': 'วันอาทิตย์',
  };
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

  late final List<String> dayValues;
  late final List<String> dayKeys;

  late int selectedDayIndex;
  int selectedNotification = 0;

  late bool _isNotificationOn;
  late bool _isExactAlarmOn;

  Future<bool> _checkPermission() async {
    if (kIsWeb) return true;

    PermissionStatus notificationStatus = await Permission.notification.status;
    PermissionStatus exactAlarmStatus =
        await Permission.scheduleExactAlarm.status;

    setState(() {
      _isNotificationOn = notificationStatus.isGranted;
      _isExactAlarmOn = exactAlarmStatus.isGranted;
    });

    if (notificationStatus.isDenied || exactAlarmStatus.isDenied) {
      return false;
    }

    return true;
  }

  @override
  void initState() {
    dayValues = days.values.toList();
    dayKeys = days.keys.toList();

    notificationTimesValues = notificationTimes.values.toList();
    notificationTimesKeys = notificationTimes.keys.toList();

    if (widget.timetable != null) {
      _subjectController.text = widget.timetable!.title;
      _locationController.text = widget.timetable!.location;
      _professorController.text = widget.timetable!.professor;
      _startTime = widget.timetable!.startTime;
      _endTime = widget.timetable!.endTime;
      isNotify = widget.timetable!.isNotify;
      notifyTime = widget.timetable!.notifyTime;
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

    selectedDayIndex = widget.dateIndex ?? DateTime.now().weekday - 1;

    WidgetsBinding.instance.addObserver(this);
    _checkPermission();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });

    requestNotificationPermission();

    super.initState();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _locationController.dispose();
    _professorController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
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
                      widget.timetable == null
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
                            builder: (context) => TimetablePage(
                              dateIndex: widget.dateIndex,
                            ),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: const Text('ยกเลิก'),
                    ),
                    TextButton(
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
          widget.timetable == null ? 'เพิ่มตารางเรียนใหม่' : 'แก้ไขตารางเรียน',
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
                      ),
                    );
                    return;
                  }

                  String userEmail = _currentUser!.email!;
                  String day = dayKeys[selectedDayIndex];

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

                  bool success;

                  if (widget.timetable != null) {
                    success = await updateTimetableEntry(
                      userEmail,
                      widget.timetableId,
                      dayKeys[widget.dateIndex!],
                      day,
                      _subjectController.text.trim(),
                      _startTime,
                      _endTime,
                      _locationController.text.trim(),
                      _professorController.text.trim(),
                      widget.timetable!.id,
                      isNotify,
                      notifyTime,
                    );
                  } else {
                    success = await addTimetableEntry(
                      userEmail,
                      widget.timetableId,
                      day,
                      _subjectController.text.trim(),
                      _startTime,
                      _endTime,
                      _locationController.text.trim(),
                      _professorController.text.trim(),
                      const Uuid().v1(),
                      isNotify,
                      notifyTime,
                    );
                  }

                  if (!context.mounted) return;

                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TimetablePage(
                        dateIndex: selectedDayIndex,
                      ),
                    ),
                    (Route<dynamic> route) => false,
                  );

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          widget.timetable == null
                              ? 'เพิ่มตารางเรียนเรียบร้อยคับ!'
                              : 'แก้ไขตารางเรียนเรียบร้อย',
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          widget.timetable == null
                              ? 'ดูเหมือนจะมีปัญหาการเพิ่มตารางเรียนนะ :('
                              : 'ดูเหมือนจะมีปัญหาการแก้ไขตารางเรียนนะ :(',
                        ),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 32),
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
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
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
                                        style: textTheme.bodyMedium!.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          children: List.generate(
                                            days.length,
                                            (index) {
                                              return RadioListTile(
                                                title: Text(dayValues[index]),
                                                value: index,
                                                groupValue: selectedDayIndex,
                                                onChanged: (value) {
                                                  setState(() {
                                                    selectedDayIndex = value!;
                                                  });
                                                  Navigator.pop(context);
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
                                dayValues[selectedDayIndex],
                                style: textTheme.bodyMedium!.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
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
                                final TimeOfDay? time = await showTimePicker(
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
                                  builder:
                                      (BuildContext context, Widget? child) {
                                    return MediaQuery(
                                      data: MediaQuery.of(context).copyWith(
                                          alwaysUse24HourFormat: true),
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
                                final TimeOfDay? time = await showTimePicker(
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
                                  builder:
                                      (BuildContext context, Widget? child) {
                                    return MediaQuery(
                                      data: MediaQuery.of(context).copyWith(
                                          alwaysUse24HourFormat: true),
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
                      FutureBuilder(
                        future: _checkPermission(),
                        builder: (context, snapshot) {
                          bool isPermissionGranted = snapshot.data ?? false;

                          return ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.notifications_outlined),
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
                                      value: !isPermissionGranted
                                          ? false
                                          : isNotify,
                                      onChanged: (value) async {
                                        if (!isPermissionGranted) {
                                          _showPermissionDialog();
                                          return;
                                        }

                                        setState(() {
                                          isNotify = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 25),
                                if (isNotify && isPermissionGranted)
                                  Row(
                                    children: [
                                      Text(
                                        'แจ้งเตือนเมื่อ',
                                        style: textTheme.bodyMedium!.copyWith(
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
                                                  style: textTheme.bodyMedium!
                                                      .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                content: SingleChildScrollView(
                                                  child: Column(
                                                    children: List.generate(
                                                      notificationTimes.length,
                                                      (index) {
                                                        return RadioListTile(
                                                          title: Text(
                                                            notificationTimesKeys[
                                                                index],
                                                          ),
                                                          value: index,
                                                          groupValue:
                                                              selectedNotification,
                                                          onChanged: (value) {
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
                                          style: textTheme.bodyMedium!.copyWith(
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: widget.timetable != null
          ? Padding(
              padding: const EdgeInsets.all(16),
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
                          TextButton(
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

                  bool success = await deleteTimetableEntry(
                    _currentUser!.email!,
                    widget.timetableId,
                    dayKeys[selectedDayIndex],
                    widget.timetable!.id,
                  );

                  if (!context.mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TimetablePage(
                        dateIndex: selectedDayIndex,
                      ),
                    ),
                    (Route<dynamic> route) => false,
                  );

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ลบตารางเรียนเรียบร้อย!'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'ดูเหมือนจะมีปัญหาการลบตารางเรียนนะ :(',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text(
                  'ลบตารางเรียน',
                ),
              ),
            )
          : null,
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

  Widget permissionList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        const Text('กรุณาเปิดการตั้งค่าแล้วเปิดการใช้งานทั้งสองฟังก์ชันนี้'),
        Row(
          spacing: 32,
          children: [
            Icon(
              _isNotificationOn
                  ? Icons.check_circle
                  : Icons.check_circle_outline_rounded,
              color: _isNotificationOn ? primaryColor : Colors.grey,
            ),
            const Text('การแจ้งเตือน'),
          ],
        ),
        Row(
          spacing: 32,
          children: [
            Icon(
              _isExactAlarmOn
                  ? Icons.check_circle
                  : Icons.check_circle_outline_rounded,
              color: _isExactAlarmOn ? primaryColor : Colors.grey,
            ),
            const Text('การปลุกและการเตือน'),
          ],
        ),
      ],
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              0,
            ),
            child: Text(
              'ดูเหมือนว่าคุณยังไม่ได้อนุญาตให้เราแจ้งเตือนได้นะ :<',
              style: textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          content: Padding(
            padding: const EdgeInsets.all(
              16,
            ),
            child: permissionList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'ยกเลิก',
              ),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
              },
              child: const Text(
                'เปิดการตั้งค่า',
              ),
            ),
          ],
        );
      },
    );
  }
}
