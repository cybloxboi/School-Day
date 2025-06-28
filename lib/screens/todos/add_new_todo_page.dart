import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:school_day/data/time.dart';
import 'package:school_day/data/todo.dart';
import 'package:school_day/screens/navigation_menu.dart';
import 'package:school_day/services/database/todo/todo_entry.dart';
import 'package:school_day/styles/styles.dart';
import 'package:school_day/styles/textfield.dart';

class AddNewTodoPage extends StatefulWidget {
  const AddNewTodoPage({
    super.key,
    required this.todoEntry,
    this.todoData,
    this.onDone,
    required this.isEdited,
  });

  final TodoEntry todoEntry;
  final Todo? todoData;
  final bool isEdited;
  final Function()? onDone;

  @override
  State<AddNewTodoPage> createState() => _AddNewTodoPageState();
}

class _AddNewTodoPageState extends State<AddNewTodoPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  // bool _notificationEnabled = false;

  final Map<String, Priority?> _priorityOptions = {
    'มาก': Priority.high,
    'กลาง': Priority.medium,
    'น้อย': Priority.low,
    'ไม่มี': null,
  };
  late String _priority;

  // late String _reminderOption;
  // late final Map<String, DateTime?> _reminderOptions;

  late Time? _alarmTime;

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();

    DateTime? picked = await showDatePicker(
      context: context,
      helpText: 'เลือกวันที่',
      cancelText: 'ยกเลิก',
      confirmText: 'ยืนยัน',
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2000),
      lastDate: DateTime(now.year + 2000),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // _reminderOptions = {
        //   '30 นาที': _selectedDate?.subtract(const Duration(minutes: 30)),
        //   '1 ชั่วโมง': _selectedDate?.subtract(const Duration(hours: 1)),
        //   '1 วัน': _selectedDate?.subtract(const Duration(days: 1)),
        //   '2 วัน': _selectedDate?.subtract(const Duration(days: 2)),
        //   '1 สัปดาห์': _selectedDate?.subtract(const Duration(days: 7)),
        // };
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _priority = widget.todoData?.priority?.toLocalizedString() ?? 'ไม่มี';
    // _reminderOption = '30 นาที';
    _alarmTime = null;

    if (widget.todoData != null) {
      _titleController.value = TextEditingValue(text: widget.todoData!.title);
      _descriptionController.value = widget.todoData!.description == null
          ? TextEditingValue.empty
          : TextEditingValue(text: widget.todoData!.description!);
      _selectedDate = widget.todoData?.selectedDate;
      _alarmTime = widget.todoData?.alarmTime;
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
                  content: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('ต้องการยกเลิกการสร้างงานนี้ใช่ไหม :<'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
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
        title: Text(
          widget.isEdited ? 'แก้ไขงาน' : 'เพิ่มงานใหม่',
          style: textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 16,
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
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

                  Todo newTodo = Todo(
                    title: _titleController.text.trim(),
                    description: _descriptionController.text.trim() == ''
                        ? null
                        : _descriptionController.text.trim(),
                    selectedDate: _selectedDate,
                    alarmTime: _alarmTime,
                    priority: _priorityOptions[_priority],
                    isDone: widget.todoData != null
                        ? widget.todoData!.isDone
                        : false,
                  );

                  bool success;

                  if (widget.isEdited) {
                    success = await widget.todoEntry.updateTodo(
                      oldTodo: widget.todoData!,
                      newTodo: newTodo,
                    );
                  } else {
                    success = await widget.todoEntry.addTodo(
                      newTodo: newTodo,
                      categoryID: widget.todoEntry.categoryID,
                    );
                  }

                  if (!context.mounted) return;

                  Navigator.pop(context);

                  if (widget.onDone == null) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NavigationMenu(
                          screenIndex: 2,
                        ),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  } else {
                    widget.onDone!();
                  }

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          !widget.isEdited
                              ? 'เพิ่มงานเรียบร้อยคับ!'
                              : 'แก้ไขงานเรียบร้อย',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          !widget.isEdited
                              ? 'ดูเหมือนจะมีปัญหาการเพิ่มงานนะ :('
                              : 'ดูเหมือนจะมีปัญหาการแก้ไขงานนะ :(',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF874B57),
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                elevation: 0,
              ),
              icon: const Icon(Icons.save_rounded, color: Colors.white),
              label: const Text(
                'บันทึก',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 32,
                  ),
                  child: Center(
                    child: Column(
                      spacing: 50,
                      children: [
                        textField(
                          _titleController,
                          'ชื่องาน',
                          Icons.book_rounded,
                          615,
                          50,
                        ),
                        textField(
                          _descriptionController,
                          'รายละเอียด',
                          Icons.description_rounded,
                          615,
                          100,
                          isMultipleLine: true,
                          isRequired: false,
                        ),
                        const Divider(),
                        Wrap(
                          runSpacing: 32,
                          spacing: 32,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 600,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(Icons.calendar_today_rounded),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'วันที่',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    onTap: _pickDate,
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0, horizontal: 4.0),
                                      child: Text(
                                        _selectedDate == null
                                            ? 'ยังไม่ได้เลือกวันที่'
                                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year + 543}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _selectedDate == null
                                              ? Colors.grey.shade600
                                              : const Color(0xFF874B57),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_selectedDate != null)
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedDate = null;
                                          // _notificationEnabled = false;
                                        });
                                      },
                                      icon: Icon(Icons.cancel_rounded),
                                    ),
                                ],
                              ),
                            ),
                            if (_selectedDate != null)
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 600,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.alarm_rounded),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'เวลา',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    const Spacer(),
                                    InkWell(
                                      onTap: () async {
                                        final TimeOfDay? time =
                                            await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay(
                                            hour: _alarmTime?.hour ?? 8,
                                            minute: _alarmTime?.minute ?? 0,
                                          ),
                                          cancelText: 'ยกเลิก',
                                          confirmText: 'ตกลง',
                                          hourLabelText: 'ชั่วโมง',
                                          minuteLabelText: 'นาที',
                                          helpText: 'เลือกเวลาแจ้งเตือน',
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

                                          _alarmTime = Time(
                                            time.hour,
                                            time.minute,
                                          );
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(4),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0, horizontal: 4.0),
                                        child: Text(
                                          _alarmTime == null
                                              ? 'ยังไม่ได้เลือกเวลา'
                                              : '$_alarmTime',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: _alarmTime == null
                                                ? Colors.grey.shade600
                                                : const Color(0xFF874B57),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_alarmTime != null)
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _alarmTime = null;
                                          });
                                        },
                                        icon: Icon(Icons.cancel_rounded),
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
                                  const Icon(Icons.flag_rounded),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'ความสำคัญ',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    onTap: () async {
                                      final selected = await showDialog<String>(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: Text(
                                              'เลือกลำดับความสำคัญ',
                                              style: textTheme.bodyMedium!
                                                  .copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                children: _priorityOptions
                                                    .entries
                                                    .map(
                                                  (entry) {
                                                    return RadioListTile(
                                                      title: Text(
                                                        entry.key,
                                                      ),
                                                      value: entry.key,
                                                      groupValue: _priority,
                                                      onChanged: (value) {
                                                        Navigator.pop(
                                                          context,
                                                          value,
                                                        );
                                                      },
                                                    );
                                                  },
                                                ).toList(),
                                              ),
                                            ),
                                          );
                                        },
                                      );

                                      if (selected != null) {
                                        setState(() {
                                          _priority = selected;
                                        });
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                        horizontal: 4.0,
                                      ),
                                      child: Text(
                                        _priority,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: const Color(0xFF874B57),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Wrap(
                            //   spacing: 32,
                            //   runSpacing: 32,
                            //   crossAxisAlignment: WrapCrossAlignment.center,
                            //   runAlignment: WrapAlignment.center,
                            //   children: [
                            //     ConstrainedBox(
                            //       constraints: const BoxConstraints(maxWidth: 600),
                            //       child: Row(
                            //         mainAxisAlignment: MainAxisAlignment.center,
                            //         crossAxisAlignment: CrossAxisAlignment.center,
                            //         children: [
                            //           const Icon(
                            //               Icons.notifications_active_rounded),
                            //           const SizedBox(width: 16),
                            //           const Text(
                            //             'แจ้งเตือนล่วงหน้า',
                            //             style: TextStyle(fontSize: 16),
                            //           ),
                            //           const Spacer(),
                            //           Switch(
                            //             value: _notificationEnabled,
                            //             onChanged: _selectedDate == null
                            //                 ? null
                            //                 : (bool newValue) {
                            //                     setState(() {
                            //                       _notificationEnabled = newValue;
                            //                     });
                            //                   },
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //     if (_notificationEnabled) ...[
                            //       ConstrainedBox(
                            //         constraints: const BoxConstraints(
                            //           maxWidth: 600,
                            //         ),
                            //         child: Row(
                            //           crossAxisAlignment: CrossAxisAlignment.center,
                            //           mainAxisAlignment: MainAxisAlignment.center,
                            //           children: [
                            //             const Text(
                            //               'แจ้งเตือนก่อน',
                            //               style: TextStyle(fontSize: 16),
                            //             ),
                            //             const Spacer(),
                            //             InkWell(
                            //               borderRadius: BorderRadius.circular(4),
                            //               onTap: () async {
                            //                 final selected =
                            //                     await showDialog<String>(
                            //                   context: context,
                            //                   builder: (context) {
                            //                     return AlertDialog(
                            //                       title: Text(
                            //                         'เลือกเวลาแจ้งเตือน',
                            //                         style: textTheme.bodyMedium!
                            //                             .copyWith(
                            //                           fontWeight: FontWeight.bold,
                            //                         ),
                            //                       ),
                            //                       content: SingleChildScrollView(
                            //                         child: Column(
                            //                           children: _reminderOptions
                            //                               .entries
                            //                               .map(
                            //                             (entry) {
                            //                               return RadioListTile(
                            //                                 title: Text(
                            //                                   entry.key,
                            //                                 ),
                            //                                 value: entry.key,
                            //                                 groupValue:
                            //                                     _reminderOption,
                            //                                 onChanged: (value) {
                            //                                   Navigator.pop(
                            //                                     context,
                            //                                     entry.key,
                            //                                   );
                            //                                 },
                            //                               );
                            //                             },
                            //                           ).toList(),
                            //                         ),
                            //                       ),
                            //                     );
                            //                   },
                            //                 );

                            //                 if (selected != null) {
                            //                   setState(() {
                            //                     _reminderOption = selected;
                            //                   });
                            //                 }
                            //               },
                            //               child: Padding(
                            //                 padding: const EdgeInsets.symmetric(
                            //                     vertical: 8.0, horizontal: 8.0),
                            //                 child: Text(
                            //                   _reminderOption,
                            //                   style: TextStyle(
                            //                     fontSize: 16,
                            //                     color: const Color(0xFF874B57),
                            //                   ),
                            //                 ),
                            //               ),
                            //             ),
                            //           ],
                            //         ),
                            //       ),
                            //     ],
                            //   ],
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              if (widget.isEdited)
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
                                child: Text('คุณต้องการลบงานใช่ไหม :<'),
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

                        bool success = await widget.todoEntry.deleteTodo(
                          todo: widget.todoData!,
                        );

                        if (!context.mounted) return;

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NavigationMenu(
                              screenIndex: 2,
                            ),
                          ),
                          (Route<dynamic> route) => false,
                        );

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ลบงานเรียบร้อย!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'ดูเหมือนจะมีปัญหาการลบงานนะ :(',
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
                          'ลบงาน',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
