import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:school_day/components/ai/action_display.dart';
import 'package:school_day/styles/styles.dart';

class AiChat extends StatefulWidget {
  const AiChat({
    super.key,
    required this.promptAnimation,
    required this.userInput,
    required this.userEmail,
    required this.geminiResponse,
  });

  final AnimationController promptAnimation;
  final String? userInput;
  final String userEmail;
  final Future<Map<String, dynamic>>? geminiResponse;

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
  });

  final String userEmail;
  final String responseText;
  final List<Map<String, dynamic>> tasks;

  @override
  State<AiProcessCard> createState() => _AiProcessCardState();
}

class _AiProcessCardState extends State<AiProcessCard> {
  late List<Map<String, dynamic>> tasks;
  late List<bool> confirmed;
  late List<bool> confirmationStatus;
  late List<bool> loading;

  Future<void> onConfirmTask(Map<String, dynamic> task) async {
    // await applyTasksToTodoList(widget.userEmail, [task]);
    await Future.delayed(const Duration(seconds: 3));
  }

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

              if (type == 'todo') {
                String title = task['title'] ?? 'ไม่ระบุชื่อ';
                String priority = task['priority'] ?? 'ไม่มี';
                String description = task['description'] ?? 'ไม่มี';
                String alarmTime = task['alarmTime'] ?? 'ไม่มี';

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
                              Icon(actionMap[action]!.icon),
                              Text(actionMap[action]!.label),
                            ],
                          ),
                          const Divider(),
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            "⏰ กำหนดส่ง: $alarmTime",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            "⭐ ความสำคัญ: $priority",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            "📝 หมายเหตุ: $description",
                            style: Theme.of(context).textTheme.bodySmall,
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
                                          WrapCrossAlignment.end,
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
                                              ? '${actionMap[action]!.label}เรียบร้อย :3'
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
                                          WrapCrossAlignment.end,
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
                                                'กำลัง${actionMap[action]!.label}...',
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

                                                  await onConfirmTask(task);

                                                  setState(() {
                                                    confirmed[index] = true;
                                                    confirmationStatus[index] =
                                                        true;
                                                    loading[index] = false;
                                                  });
                                                },
                                              ),
                                              FilledButton.tonalIcon(
                                                icon: const Icon(
                                                  Icons.edit_rounded,
                                                ),
                                                label: const Text("แก้ไข"),
                                                onPressed: () {},
                                              ),
                                              TextButton.icon(
                                                icon: const Icon(
                                                    Icons.cancel_rounded),
                                                label: const Text("ปัดทิ้ง"),
                                                onPressed: () {
                                                  setState(() {
                                                    confirmed[index] = true;
                                                  });
                                                },
                                              ),
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
                String title = task['title'] ?? 'ไม่ระบุชื่อ';
                String startTime = task['startTime'] ?? 'ไม่มี';
                String endTime = task['endTime'] ?? 'ไม่มี';
                String location = task['location'] ?? 'ไม่มี';
                String professor = task['professor'] ?? 'ไม่มี';
                bool isNotify = task['isNotify'];
                String notifyTime = task['notifyTime'] ?? 'ไม่มี';

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
                              Icon(actionMap[action]!.icon),
                              Text(actionMap[action]!.label),
                            ],
                          ),
                          const Divider(),
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            "⏰ เวลาเริ่ม - สิ้นสุด: $startTime - $endTime",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            "⭐ สถานที่: $location",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            "⭐ ผู้สอน: $professor",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (isNotify)
                            Text(
                              "📝 แจ้งเตือน: $notifyTime",
                              style: Theme.of(context).textTheme.bodySmall,
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
                                          WrapCrossAlignment.end,
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
                                              ? '${actionMap[action]!.label}เรียบร้อย :3'
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
                                          WrapCrossAlignment.end,
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
                                                'กำลัง${actionMap[action]!.label}...',
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

                                                  await onConfirmTask(task);

                                                  setState(() {
                                                    confirmed[index] = true;
                                                    confirmationStatus[index] =
                                                        true;
                                                    loading[index] = false;
                                                  });
                                                },
                                              ),
                                              FilledButton.tonalIcon(
                                                icon: const Icon(
                                                  Icons.edit_rounded,
                                                ),
                                                label: const Text("แก้ไข"),
                                                onPressed: () {},
                                              ),
                                              TextButton.icon(
                                                icon: const Icon(
                                                    Icons.cancel_rounded),
                                                label: const Text("ปัดทิ้ง"),
                                                onPressed: () {
                                                  setState(() {
                                                    confirmed[index] = true;
                                                  });
                                                },
                                              ),
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
