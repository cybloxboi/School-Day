import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:school_day/components/ai/action_display.dart';
import 'package:school_day/components/others/format_alarm_time.dart';
import 'package:school_day/data/time.dart';
import 'package:school_day/data/timetable.dart';
import 'package:school_day/data/todo.dart';
import 'package:school_day/screens/timetables/add_new_timetable_page.dart';
import 'package:school_day/screens/todos/add_new_todo_page.dart';
import 'package:school_day/services/database/timetable/timetable_entry.dart';
import 'package:school_day/services/database/todo/todo_entry.dart';
import 'package:school_day/styles/styles.dart';

class AiChat extends StatefulWidget {
  const AiChat({
    super.key,
    required this.promptAnimation,
    required this.userInput,
    required this.userEmail,
    required this.geminiResponse,
    required this.timetableId,
    required this.categoryId,
  });

  final AnimationController promptAnimation;
  final String? userInput;
  final String userEmail;
  final Future<Map<String, dynamic>>? geminiResponse;
  final String timetableId;
  final String categoryId;

  @override
  State<AiChat> createState() => _AiChatState();
}

class _AiChatState extends State<AiChat> with TickerProviderStateMixin {
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: widget.promptAnimation,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: widget.promptAnimation,
      curve: Curves.easeIn,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userInput ?? '',
                  style: textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                if (widget.geminiResponse != null)
                  FutureBuilder<Map<String, dynamic>>(
                    future: widget.geminiResponse,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Row(
                          children: [
                            LoadingAnimationWidget.staggeredDotsWave(
                              color: primaryColor,
                              size: 30,
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'กำลังจัดการงานให้คุณ...',
                            ),
                          ],
                        );
                      }

                      if (snapshot.hasError) {
                        return const Text(
                          'เกิดข้อผิดพลาด กรุณาลองใหม่',
                        );
                      }

                      if (!snapshot.hasData) {
                        return const SizedBox();
                      }

                      final data = snapshot.data!;
                      final responseText = data['replyText'] ?? '';
                      final originalTasks =
                          List<Map<String, dynamic>>.from(data['tasks'] ?? []);

                      return AiProcessCard(
                        userEmail: widget.userEmail,
                        responseText: responseText,
                        tasks: originalTasks,
                        timetableId: widget.timetableId,
                        categoryId: widget.categoryId,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AiProcessCard extends StatefulWidget {
  const AiProcessCard({
    super.key,
    required this.userEmail,
    required this.responseText,
    required this.tasks,
    required this.timetableId,
    required this.categoryId,
  });

  final String userEmail;
  final String responseText;
  final List<Map<String, dynamic>> tasks;
  final String timetableId;
  final String categoryId;

  @override
  State<AiProcessCard> createState() => _AiProcessCardState();
}

class _AiProcessCardState extends State<AiProcessCard> {
  late List<Map<String, dynamic>> tasks;
  late List<bool> confirmed;
  late List<bool> confirmationStatus;
  late List<bool> loading;

  @override
  void initState() {
    super.initState();

    tasks = [...widget.tasks];
    confirmed = List.filled(tasks.length, false);
    loading = List.filled(tasks.length, false);
    confirmationStatus = List.filled(tasks.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        Text(
          widget.responseText,
          style: textTheme.bodySmall,
        ),
        if (tasks.isNotEmpty)
          ...tasks.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final task = entry.value;

              String type = task['type'];
              String action = task['action'];
              ActionDisplay actionDisplay = getActionDisplay(action, type);

              if (type == 'todo') {
                final newTodo = task['newTodo'];
                final oldTodo = task['oldTodo'];

                String? id = newTodo['id'];
                String title = newTodo['title'] ?? 'ไม่ระบุชื่อ';
                String? priority = newTodo['priority'];
                String? description = newTodo['description'];
                DateTime? selectedDate = newTodo['selectedDate'] != null
                    ? DateTime.tryParse(newTodo['selectedDate'])
                    : null;
                Time? alarmTime = newTodo['alarmTime'] != null
                    ? Time.fromJson(newTodo['alarmTime'])
                    : null;

                final Map<String, Priority?> priorityOptions = {
                  'high': Priority.high,
                  'medium': Priority.medium,
                  'low': Priority.low,
                  'none': null,
                };

                final oldPriorityKey = oldTodo?['priority'];
                final Priority? currentPriority = priorityOptions[priority];
                final Priority? oldPriority = priorityOptions[oldPriorityKey];

                TodoEntry todoEntry = TodoEntry(
                  email: widget.userEmail,
                  categoryID: widget.categoryId,
                );

                Todo todo = Todo(
                  id: id,
                  title: title,
                  description: description,
                  selectedDate: selectedDate,
                  alarmTime: alarmTime,
                  priority: priorityOptions[priority],
                );

                return AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 16,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 8,
                            children: [
                              Icon(actionDisplay.icon),
                              Text(actionDisplay.label),
                            ],
                          ),
                          const Divider(),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (oldTodo != null && oldTodo['title'] != title)
                                Text(
                                  oldTodo['title'],
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      ),
                                ),
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          if (description != null)
                            RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodySmall,
                                children: [
                                  const WidgetSpan(
                                    child: Icon(Icons.description_rounded,
                                        size: 18),
                                    alignment: PlaceholderAlignment.middle,
                                  ),
                                  const TextSpan(text: " รายละเอียด: "),
                                  if (oldTodo != null &&
                                      oldTodo['description'] != description)
                                    TextSpan(
                                      text: '${oldTodo['description']} ',
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  TextSpan(
                                    text: description,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (selectedDate != null)
                            RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodySmall,
                                children: [
                                  const WidgetSpan(
                                    child: Icon(Icons.access_alarm, size: 18),
                                    alignment: PlaceholderAlignment.middle,
                                  ),
                                  const TextSpan(text: " กำหนดส่ง: "),
                                  TextSpan(
                                    text:
                                        '${formatAlarmTime(selectedDate.toIso8601String())} ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (alarmTime != null)
                                    TextSpan(
                                      text: 'เวลา: ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  if (oldTodo != null &&
                                      alarmTime != null &&
                                      Time.fromJson(oldTodo['alarmTime']) !=
                                          alarmTime)
                                    TextSpan(
                                      text: Time.fromJson(oldTodo['alarmTime'])
                                          .toString(),
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  if (alarmTime != null)
                                    TextSpan(
                                      text: alarmTime.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          if (priority != 'none')
                            RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodySmall,
                                children: [
                                  const WidgetSpan(
                                    child: Icon(Icons.star,
                                        size: 18, color: Colors.amber),
                                    alignment: PlaceholderAlignment.middle,
                                  ),
                                  const TextSpan(text: " ความสำคัญ: "),
                                  if (oldPriority != null &&
                                      oldPriority != currentPriority)
                                    TextSpan(
                                      text: oldPriority.toLocalizedString(),
                                      style: const TextStyle(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  if (currentPriority != null)
                                    TextSpan(
                                      text: currentPriority.toLocalizedString(),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                ],
                              ),
                            ),
                          const Divider(),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: SizeTransition(
                                  sizeFactor: animation,
                                  axisAlignment: -1.0,
                                  child: child,
                                ),
                              ),
                              child: confirmed[index]
                                  ? Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.start,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Icon(
                                          confirmationStatus[index]
                                              ? Icons.check_circle_rounded
                                              : Icons.cancel_rounded,
                                          color: confirmationStatus[index]
                                              ? primaryColor
                                              : null,
                                        ),
                                        Text(
                                          confirmationStatus[index]
                                              ? '${actionDisplay.label}เรียบร้อย :3'
                                              : 'ปัดทิ้ง :<',
                                          style: textTheme.bodySmall!.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Wrap(
                                      key: ValueKey('buttons-$index'),
                                      alignment: WrapAlignment.start,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: loading[index]
                                          ? [
                                              LoadingAnimationWidget
                                                  .threeArchedCircle(
                                                color: primaryColor,
                                                size: 20,
                                              ),
                                              Text(
                                                'กำลัง${actionDisplay.label}...',
                                                style: textTheme.bodySmall,
                                              ),
                                            ]
                                          : [
                                              FilledButton.icon(
                                                icon: const Icon(
                                                  Icons.check_rounded,
                                                ),
                                                label: const Text("ยืนยัน"),
                                                onPressed: () async {
                                                  setState(() {
                                                    loading[index] = true;
                                                  });

                                                  bool success = false;

                                                  if (action == 'add') {
                                                    success =
                                                        await todoEntry.addTodo(
                                                      newTodo: todo,
                                                      categoryID:
                                                          todoEntry.categoryID,
                                                    );
                                                  } else if (action ==
                                                      'update') {
                                                    success = await todoEntry
                                                        .updateTodo(
                                                      oldTodo: Todo.fromJson(
                                                          oldTodo),
                                                      newTodo: todo,
                                                    );
                                                  } else if (action ==
                                                      'delete') {
                                                    success = await todoEntry
                                                        .deleteTodo(
                                                      todo: todo,
                                                    );
                                                  }

                                                  if (success) {
                                                    setState(() {
                                                      confirmed[index] = true;
                                                      confirmationStatus[
                                                          index] = true;
                                                      loading[index] = false;
                                                    });
                                                  }
                                                },
                                              ),
                                              if (action != 'delete')
                                                FilledButton.tonalIcon(
                                                  icon: const Icon(
                                                    Icons.edit_rounded,
                                                  ),
                                                  label: const Text("แก้ไข"),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            AddNewTodoPage(
                                                          todoEntry: todoEntry,
                                                          todoData: todo,
                                                          isEdited:
                                                              action == 'add'
                                                                  ? false
                                                                  : true,
                                                          onDone: () {
                                                            Navigator.pop(
                                                              context,
                                                            );

                                                            setState(() {
                                                              confirmed[index] =
                                                                  true;
                                                              confirmationStatus[
                                                                  index] = true;
                                                              loading[index] =
                                                                  false;
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              // TextButton.icon(
                                              //   icon: const Icon(
                                              //       Icons.cancel_rounded),
                                              //   label: const Text("ปัดทิ้ง"),
                                              //   onPressed: () {
                                              //     setState(() {
                                              //       confirmed[index] = true;
                                              //     });
                                              //   },
                                              // ),
                                            ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else if (type == 'timetable') {
                final newTimetable = task['newTimetable'];
                final oldTimetable = task['oldTimetable'];

                String title = newTimetable['title'] ?? 'ไม่ระบุชื่อ';
                Time startTime = newTimetable['startTime'] != null
                    ? Time.fromJson(newTimetable['startTime'])
                    : Time(0, 0);
                Time endTime = newTimetable['endTime'] != null
                    ? Time.fromJson(newTimetable['endTime'])
                    : Time(1, 0);
                String location = newTimetable['location'] ?? 'ไม่มี';
                String professor = newTimetable['professor'] ?? 'ไม่มี';
                int dayIndex = newTimetable['dateIndex'] ?? 0;
                String date = newTimetable['date'] ?? 'วันจันทร์';

                TimetableEntry timetableEntry = TimetableEntry(
                  email: widget.userEmail,
                  timetableID: widget.timetableId,
                  dayIndex: dayIndex,
                );

                Timetable timetable = Timetable(
                  id: newTimetable['id'],
                  title: title,
                  professor: professor,
                  location: location,
                  startTime: startTime,
                  endTime: endTime,
                  isNotify: true,
                  notifyTime: Time(0, 0),
                );

                return AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 16,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 8,
                            children: [
                              Icon(actionDisplay.icon),
                              Text(actionDisplay.label),
                            ],
                          ),
                          const Divider(),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (oldTimetable != null &&
                                  oldTimetable['title'] != title)
                                Text(
                                  oldTimetable['title'],
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      ),
                                ),
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodySmall,
                              children: [
                                const WidgetSpan(
                                  child:
                                      Icon(Icons.date_range_rounded, size: 18),
                                  alignment: PlaceholderAlignment.middle,
                                ),
                                const TextSpan(text: " วันที่เรียน: "),
                                if (oldTimetable != null &&
                                    oldTimetable['date'] != date)
                                  TextSpan(
                                    text: oldTimetable['date'],
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                                  ),
                                TextSpan(
                                  text: date,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodySmall,
                              children: [
                                const WidgetSpan(
                                  child: Icon(Icons.access_alarm, size: 18),
                                  alignment: PlaceholderAlignment.middle,
                                ),
                                const TextSpan(text: " เวลาเริ่ม - สิ้นสุด: "),
                                if (oldTimetable != null &&
                                        Time.fromJson(
                                                oldTimetable['startTime']) !=
                                            startTime ||
                                    Time.fromJson(oldTimetable['endTime']) !=
                                        endTime)
                                  TextSpan(
                                    text:
                                        '${Time.fromJson(oldTimetable['startTime'])} - ${Time.fromJson(oldTimetable['endTime'])}',
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                                  ),
                                TextSpan(
                                  text: '$startTime - $endTime',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodySmall,
                              children: [
                                const WidgetSpan(
                                  child: Icon(Icons.location_city_rounded,
                                      size: 18),
                                  alignment: PlaceholderAlignment.middle,
                                ),
                                const TextSpan(text: " สถานที่: "),
                                if (oldTimetable != null &&
                                    oldTimetable['location'] != location)
                                  TextSpan(
                                    text: '${oldTimetable['location']}',
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                                  ),
                                TextSpan(
                                  text: location,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodySmall,
                              children: [
                                const WidgetSpan(
                                  child: Icon(Icons.person_rounded, size: 18),
                                  alignment: PlaceholderAlignment.middle,
                                ),
                                const TextSpan(text: " ผู้สอน: "),
                                if (oldTimetable != null &&
                                    oldTimetable['professor'] != professor)
                                  TextSpan(
                                    text: '${oldTimetable['professor']}',
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                                  ),
                                TextSpan(
                                  text: professor,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: SizeTransition(
                                  sizeFactor: animation,
                                  axisAlignment: -1.0,
                                  child: child,
                                ),
                              ),
                              child: confirmed[index]
                                  ? Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.start,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Icon(
                                          confirmationStatus[index]
                                              ? Icons.check_circle_rounded
                                              : Icons.cancel_rounded,
                                          color: confirmationStatus[index]
                                              ? primaryColor
                                              : null,
                                        ),
                                        Text(
                                          confirmationStatus[index]
                                              ? '${actionDisplay.label}เรียบร้อย :3'
                                              : 'ปัดทิ้ง :<',
                                          style: textTheme.bodySmall!.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Wrap(
                                      key: ValueKey('buttons-$index'),
                                      alignment: WrapAlignment.start,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: loading[index]
                                          ? [
                                              LoadingAnimationWidget
                                                  .threeArchedCircle(
                                                color: primaryColor,
                                                size: 20,
                                              ),
                                              Text(
                                                'กำลัง${actionDisplay.label}...',
                                                style: textTheme.bodySmall,
                                              ),
                                            ]
                                          : [
                                              FilledButton.icon(
                                                icon: const Icon(
                                                  Icons.check_rounded,
                                                ),
                                                label: const Text("ยืนยัน"),
                                                onPressed: () async {
                                                  setState(() {
                                                    loading[index] = true;
                                                  });

                                                  bool success = false;

                                                  if (action == 'add') {
                                                    success =
                                                        await timetableEntry
                                                            .addLesson(
                                                      selectedDayIndex:
                                                          dayIndex,
                                                      newLesson: timetable,
                                                    );
                                                  } else if (action ==
                                                      'update') {
                                                    success =
                                                        await timetableEntry
                                                            .updateLesson(
                                                      newDayIndex: dayIndex,
                                                      oldLesson:
                                                          Timetable.fromJson(
                                                        oldTimetable,
                                                      ),
                                                      updatedLesson: timetable,
                                                    );
                                                  } else if (action ==
                                                      'delete') {
                                                    success =
                                                        await timetableEntry
                                                            .deleteLesson(
                                                      lesson: timetable,
                                                    );
                                                  }

                                                  if (success) {
                                                    setState(() {
                                                      confirmed[index] = true;
                                                      confirmationStatus[
                                                          index] = true;
                                                      loading[index] = false;
                                                    });
                                                  }
                                                },
                                              ),
                                              if (action != 'delete')
                                                FilledButton.tonalIcon(
                                                  icon: const Icon(
                                                    Icons.edit_rounded,
                                                  ),
                                                  label: const Text("แก้ไข"),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            AddNewTimetablePage(
                                                          timetableEntry:
                                                              timetableEntry,
                                                          timetableData:
                                                              timetable,
                                                          isEdited:
                                                              action == 'add'
                                                                  ? false
                                                                  : true,
                                                          onDone: () {
                                                            Navigator.pop(
                                                              context,
                                                            );

                                                            setState(() {
                                                              confirmed[index] =
                                                                  true;
                                                              confirmationStatus[
                                                                  index] = true;
                                                              loading[index] =
                                                                  false;
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              // TextButton.icon(
                                              //   icon: const Icon(
                                              //       Icons.cancel_rounded),
                                              //   label: const Text("ปัดทิ้ง"),
                                              //   onPressed: () {
                                              //     setState(() {
                                              //       confirmed[index] = true;
                                              //     });
                                              //   },
                                              // ),
                                            ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                return Text('Error');
              }
            },
          ),
      ],
    );
  }
}
