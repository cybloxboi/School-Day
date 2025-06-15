import 'package:flutter/material.dart';
import 'package:school_day/data/todo.dart';
import 'package:school_day/styles/styles.dart';
import 'package:school_day/styles/textfield.dart';

class AddNewTodoPage extends StatefulWidget {
  const AddNewTodoPage({super.key});

  @override
  State<AddNewTodoPage> createState() => _AddNewTodoPageState();
}

class _AddNewTodoPageState extends State<AddNewTodoPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  bool _notificationEnabled = false;

  final Map<String, Priority?> _priorityOptions = {
    'มาก': Priority.high,
    'กลาง': Priority.medium,
    'น้อย': Priority.low,
    'ไม่มี': null,
  };
  late String _priority;

  String _reminderOption = '1 วันก่อน';
  final List<String> _reminderOptions = [
    '1 วันก่อน',
    '2 วันก่อน',
    '1 สัปดาห์ก่อน',
    'กำหนดเอง',
  ];
  int _customDaysBefore = 1;

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      helpText: 'เลือกวันที่',
      cancelText: 'ยกเลิก',
      confirmText: 'ยืนยัน',
      initialDate: _selectedDate ?? now,
      firstDate: DateTime.now(),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _priority = 'ไม่มี';
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
                        Navigator.of(context).popUntil(
                          (route) => route.isFirst,
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
        title: Text(
          'เพิ่มงานใหม่',
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
              onPressed: () {},
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
          child: Form(
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
                                          style: textTheme.bodyMedium!.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            children:
                                                _priorityOptions.entries.map(
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
                        Wrap(
                          spacing: 32,
                          runSpacing: 32,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runAlignment: WrapAlignment.center,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(
                                      Icons.notifications_active_rounded),
                                  const SizedBox(width: 16),
                                  const Text(
                                    'แจ้งเตือนล่วงหน้า',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: _notificationEnabled,
                                    onChanged: (bool newValue) {
                                      setState(() {
                                        _notificationEnabled = newValue;
                                        if (!newValue) {
                                          _reminderOption = '1 วันก่อน';
                                          _customDaysBefore = 1;
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            if (_notificationEnabled) ...[
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 600,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'แจ้งเตือนเมื่อ',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    const Spacer(),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(4),
                                      onTap: () async {
                                        final selected =
                                            await showDialog<String>(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text(
                                                  'เลือกเวลาการแจ้งเตือน'),
                                              content: SizedBox(
                                                width: double.minPositive,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: _reminderOptions
                                                      .map((option) {
                                                    return ListTile(
                                                      title: Center(
                                                          child: Text(option)),
                                                      onTap: () =>
                                                          Navigator.pop(
                                                              context, option),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                        if (selected != null) {
                                          setState(() {
                                            _reminderOption = selected;
                                            if (selected != 'กำหนดเอง') {
                                              _customDaysBefore = 1;
                                            }
                                          });
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0, horizontal: 8.0),
                                        child: Text(
                                          _reminderOption,
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
                              if (_reminderOption == 'กำหนดเอง') ...[
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: 600,
                                  ),
                                  child: Row(
                                    children: [
                                      const Text('ก่อนส่งงานกี่วัน',
                                          style: TextStyle(fontSize: 16)),
                                      const Spacer(),
                                      SizedBox(
                                        width: 60,
                                        child: TextFormField(
                                          initialValue:
                                              _customDaysBefore.toString(),
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {
                                            final int? val =
                                                int.tryParse(value);
                                            if (val != null && val >= 0) {
                                              setState(() {
                                                _customDaysBefore = val;
                                              });
                                            }
                                          },
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 8),
                                          ),
                                        ),
                                      ),
                                      const Text(' วัน'),
                                    ],
                                  ),
                                ),
                              ],
                            ],
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
    );
  }
}
