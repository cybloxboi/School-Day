import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:school_day/services/timetable_database/timetable_set.dart';
import 'package:school_day/styles/styles.dart';

class AddTimetablesetsPage extends StatefulWidget {
  const AddTimetablesetsPage({
    super.key,
    required this.isEdited,
    required this.isCurrent,
    required this.timetableSetDocument,
    this.name,
    this.timetableID,
  });

  final bool isEdited;
  final bool isCurrent;
  final TimetableSetDocument timetableSetDocument;
  final String? name;
  final String? timetableID;

  @override
  State<AddTimetablesetsPage> createState() => _AddTimetablesetsPageState();
}

class _AddTimetablesetsPageState extends State<AddTimetablesetsPage> {
  final _formKey = GlobalKey<FormState>();
  final _timetablesetNameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.name != null) {
      _timetablesetNameController.text = widget.name!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              IconButton.filledTonal(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.cancel_rounded),
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            !widget.isEdited ? 'เพิ่มเซตตารางเรียนใหม่' : 'แก้ไขเซตตารางเรียน',
            style: textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(),
          const SizedBox(
            height: 16,
          ),
          Row(
            children: [
              Flexible(
                child: Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _timetablesetNameController,
                    decoration: const InputDecoration(
                      hintText: 'ชื่อเซตตารางเรียน',
                    ),
                    maxLength: 25,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'กรุณากรอกชื่อเซตตารางเรียนด้วยนะงับ';
                      }

                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 32),
              FilledButton.tonal(
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

                    if (!widget.isEdited) {
                      await widget.timetableSetDocument.createNewTimetableSet(
                        name: _timetablesetNameController.text.trim(),
                      );
                    } else {
                      await widget.timetableSetDocument.updateTimetableSet(
                        name: _timetablesetNameController.text.trim(),
                        timetableID: widget.timetableID!,
                      );
                    }

                    if (!context.mounted) return;

                    Navigator.pop(context);
                    Navigator.pop(context);
                  }
                },
                child: const Icon(Icons.save_rounded),
              ),
            ],
          ),
          if (widget.isEdited)
            Column(
              children: [
                const SizedBox(
                  height: 16,
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: widget.isCurrent
                            ? null
                            : () async {
                                bool? confirmDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      content: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          'คุณต้องการลบเซตตารางเรียนใช่ไหม :<',
                                        ),
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

                                if (confirmDelete != true || !context.mounted) {
                                  return;
                                }

                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => Center(
                                    child:
                                        LoadingAnimationWidget.fourRotatingDots(
                                      color: primaryColor,
                                      size: 80,
                                    ),
                                  ),
                                );

                                await widget.timetableSetDocument
                                    .deleteTimetableSet(
                                  timetableID: widget.timetableID!,
                                );

                                if (!context.mounted) return;

                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                        icon: const Icon(Icons.delete_rounded),
                        label: Text(
                          widget.isCurrent
                              ? 'กรุณาเปลี่ยน หรือเพิ่มเซตตารางเรียนใหม่เพื่อลบ'
                              : 'ลบเซตตารางเรียน',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
