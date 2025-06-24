import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:school_day/components/ai/ai_chat.dart';
import 'package:school_day/services/gemini/gemini_service.dart';
import 'package:school_day/styles/styles.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  late final AnimationController _promptAnimation;
  final TextEditingController _promptController = TextEditingController();

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>>? _geminiResponse;

  bool _isButtonEnabled = false;
  bool _isLoading = false;
  String? _userInput;

  late String timetableId;
  late String categoryId;

  void sendPrompt() async {
    FocusScope.of(context).unfocus();

    final input = _promptController.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _isLoading = true;
      _userInput = input;
      _promptController.clear();
      _geminiResponse = GeminiService.ask(
        userMessage: input,
        email: _currentUser!.email!,
        categoryId: categoryId,
        timetableId: timetableId,
      );
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

  Future<void> fetchTimetableInfo(String userEmail) async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('Users').doc(userEmail);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        final data = snapshot.data();
        timetableId = data?['currentTimetableID'];
        categoryId = data?['currentCategoryID'];

        debugPrint('currentTimetableID: $timetableId');
        debugPrint('currentCategoryID: $categoryId');
      } else {
        debugPrint('User document does not exist');
      }
    } catch (e) {
      debugPrint('Error fetching document: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    fetchTimetableInfo(_currentUser!.email!);

    _promptAnimation = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 300,
      ),
    );

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
            child: !kDebugMode
                ? Text('ขออภัย ตอนนี้กำลังอยู่ช่วงปิดปรับปรุง')
                : Column(
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
                                  ],
                                )
                              : AiChat(
                                  userInput: _userInput,
                                  geminiResponse: _geminiResponse,
                                  promptAnimation: _promptAnimation,
                                  userEmail: _currentUser!.email!,
                                  timetableId: timetableId,
                                  categoryId: categoryId,
                                ),
                        ),
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
                                      ? LoadingAnimationWidget
                                          .staggeredDotsWave(
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
