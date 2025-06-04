import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

class WelcomeText extends StatefulWidget {
  const WelcomeText({super.key});

  @override
  State<WelcomeText> createState() => _WelcomeTextState();
}

class _WelcomeTextState extends State<WelcomeText> {
  final List<String> messages = [
    'มาดูกันสิ วันนี้มีอะไรบ้าง',
    'ขอให้วันนี้เป็นวันที่โชคดี',
    'วันนี้มาตั้งใจเรียนไปด้วยกันนะ',
    'อย่าลืมยิ้มให้ตัวเองในวันนี้นะ',
    'เริ่มต้นวันใหม่ด้วยพลังบวกกันเถอะ',
    'วันนี้ก็เป็นอีกวันที่เราจะพัฒนาตัวเอง',
    'พร้อมลุยกับภารกิจของวันนี้หรือยัง?',
    'เรียนรู้สิ่งใหม่ ๆ ไปด้วยกันนะ',
    'ไม่ว่าจะเจออะไร วันนี้เราจะผ่านมันไปได้',
    'ขอให้วันนี้เต็มไปด้วยความสุขและรอยยิ้ม',
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedTextKit(
      repeatForever: true,
      pause: const Duration(seconds: 5),
      animatedTexts: messages.map((message) {
        return TypewriterAnimatedText(message);
      }).toList(),
    );
  }
}
