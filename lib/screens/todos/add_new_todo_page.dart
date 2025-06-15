import 'package:flutter/material.dart';
import 'package:school_day/styles/styles.dart';

class AddNewTodoPage extends StatefulWidget {
  const AddNewTodoPage({super.key});

  @override
  State<AddNewTodoPage> createState() => _AddNewTodoPageState();
}

class _AddNewTodoPageState extends State<AddNewTodoPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _selectedDate; 
  bool _notificationEnabled = false;

  
  String? _priority;
  final List<String> _priorityOptions = ['มาก', 'กลาง', 'น้อย'];
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
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
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
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context); // ปิด dialog
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
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.book_rounded),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            hintText: 'ชื่องาน',
                            counterText: '0/50',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.description_rounded),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            hintText: 'รายละเอียด',
                            counterText: '0/100',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(
                    height: 80,
                    thickness: 1,
                    color: Colors.black26,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded),
                      const SizedBox(width: 6),
                      const Text(
                        'วันที่ส่ง',
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
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
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
                  const SizedBox(height: 32),
                 Row(
                    children: [
                      const Icon(Icons.flag_rounded),
                      const SizedBox(width: 6),
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
                                title: const Text('เลือกความสำคัญ'),
                                content: SizedBox(
                                  width: double.minPositive,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: _priorityOptions.map((priority) {
                                      return ListTile(
                                        title: Center(child: Text(priority)),
                                        onTap: () => Navigator.pop(context, priority),
                                      );
                                    }).toList(),
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
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                          child: Text(
                            _priority ?? 'ยังไม่ได้เลือกความสำคัญ',
                            style: TextStyle(
                              fontSize: 16,
                              color: _priority == null ? Colors.grey.shade600 : 
                              const Color(0xFF874B57),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded),
                      const SizedBox(width: 6),
                      const Text(
                        'แจ้งเตือนวันส่งงาน',
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

                  if (_notificationEnabled) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const SizedBox(width: 36),
                        const Text(
                          'แจ้งเตือนเมื่อ',
                          style: TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () async {
                            final selected = await showDialog<String>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text('เลือกเวลาการแจ้งเตือน'),
                                  content: SizedBox(
                                    width: double.minPositive,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: _reminderOptions.map((option) {
                                        return ListTile(
                                          title: Center(child: Text(option)),
                                          onTap: () => Navigator.pop(context, option),
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
                            padding:
                                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                            child: Text(
                              _reminderOption,
                              style: TextStyle(
                                fontSize: 16,
                                color: _reminderOption == null
                                    ? Colors.grey.shade600
                                    : const Color(0xFF874B57),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 36),
                      ],
                    ),

                    if (_reminderOption == 'กำหนดเอง') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 36),
                          const Text('ก่อนส่งงานกี่วัน: ', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: TextFormField(
                              initialValue: _customDaysBefore.toString(),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final int? val = int.tryParse(value);
                                if (val != null && val >= 0) {
                                  setState(() {
                                    _customDaysBefore = val;
                                  });
                                }
                              },
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                            ),
                          ),
                          const Text(' วัน'),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
