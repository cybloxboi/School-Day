import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:school_day/services/gemini/gemini_service.dart';
import 'package:school_day/styles/styles.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  late final AnimationController _promptAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  final TextEditingController _promptController = TextEditingController();

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>>? _geminiResponse;

  bool _isButtonEnabled = false;
  bool _isLoading = false;
  String? _userInput;

  final List<String> _exampleCommands = [
    'เพิ่มงานคณิตศาสตร์ส่งพรุ่งนี้ตอนสองทุ่ม',
    'งานเขียนรายงานไม่ต้องแล้ว ลบออกเลย',
    'ย้ายกำหนดส่งงานภาษาอังกฤษไปวันจันทร์แทน',
    'ฝากเตือนให้อ่านหนังสือสอบชีวะวันอาทิตย์ตอนเย็น',
    'ขอเปลี่ยนเวลาส่งงานคณิตเป็นหกโมงเย็น',
  ];

  void sendPrompt() async {
    FocusScope.of(context).unfocus();

    final input = _promptController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isLoading = true;
      _userInput = input;
      _promptController.clear();
      _geminiResponse = GeminiService.ask(input, _currentUser!.email!);
    });

    _promptAnimation.forward(from: 0);

    try {
      await _geminiResponse;
    } catch (e) {
      debugPrint("❌ Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _promptAnimation = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 300,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _promptAnimation,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _promptAnimation,
      curve: Curves.easeIn,
    ));

    _promptController.addListener(() {
      final isNotEmpty = _promptController.text.trim().isNotEmpty;

      if (_isButtonEnabled != isNotEmpty) {
        setState(() {
          _isButtonEnabled = isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _promptAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          'School Day AI',
          style: textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: _userInput == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 16,
                            children: [
                              Text(
                                'สวัสดี!',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium!.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'มีอะไรให้ช่วยไหม?',
                                style: textTheme.bodyMedium!.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              LottieBuilder.asset(
                                'assets/animations/ai_introduction.json',
                                frameRate: FrameRate.max,
                                width: 300,
                                height: 300,
                              ),
                              Text(
                                'ทดลองใช้คำสั่งเช่น ',
                                style: textTheme.bodySmall!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  AnimatedTextKit(
                                    repeatForever: true,
                                    pause: const Duration(seconds: 3),
                                    animatedTexts:
                                        _exampleCommands.map((command) {
                                      return TypewriterAnimatedText(
                                        '"$command"',
                                        textStyle: textTheme.bodySmall,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 700),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userInput!,
                                        style: textTheme.bodySmall!.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Divider(),
                                      if (_geminiResponse != null)
                                        FutureBuilder<Map<String, dynamic>>(
                                          future: _geminiResponse,
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Row(
                                                children: [
                                                  LoadingAnimationWidget
                                                      .staggeredDotsWave(
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
                                            final responseText =
                                                data['responseText'] ?? '';
                                            final tasks = data['tasks'];

                                            return Column(
                                              spacing: 32,
                                              children: [
                                                Text(responseText),
                                                if (tasks != null &&
                                                    tasks.isNotEmpty)
                                                  ...tasks.map((task) {
                                                    final action =
                                                        task['action'];
                                                    final title =
                                                        task['title'] ??
                                                            'ไม่ระบุชื่อ';
                                                    final due = task['due'];
                                                    final priority =
                                                        task['priority'];
                                                    final note = task['note'];

                                                    return Card(
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 8),
                                                      elevation: 2,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(16),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              "$title (${action.toUpperCase()})",
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .titleMedium,
                                                            ),
                                                            if (due != null)
                                                              Text(
                                                                "⏰ กำหนดส่ง: ${due.toString().replaceFirst('T', ' ').split('.').first}",
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodySmall,
                                                              ),
                                                            if (priority !=
                                                                null)
                                                              Text(
                                                                "⭐ ความสำคัญ: $priority",
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodySmall,
                                                              ),
                                                            if (note != null)
                                                              Text(
                                                                "📝 หมายเหตุ: $note",
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodySmall,
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                              ],
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                const Text(
                  'สำคัญ! : โปรดโน้ตว่า AI นั้นมีผิดพลาดได้เสมอ โปรดตรวจสอบข้อมูลก่อนดำเนินการ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(
                  height: 16,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 8, 8, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _promptController,
                              decoration: const InputDecoration.collapsed(
                                hintText: 'ลองถาม AI ดูสิ',
                              ),
                              onEditingComplete: sendPrompt,
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          IconButton.filledTonal(
                            onPressed: !_isButtonEnabled || _isLoading
                                ? null
                                : sendPrompt,
                            icon: _isLoading
                                ? LoadingAnimationWidget.staggeredDotsWave(
                                    color: Colors.grey,
                                    size: 20,
                                  )
                                : const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
