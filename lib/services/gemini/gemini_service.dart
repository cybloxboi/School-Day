import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:school_day/api_key.dart';

class GeminiService {
  static Future<Map<String, dynamic>> ask({
    required String userMessage,
    required String email,
  }) async {
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiKey';

    // TODO: รับข้อมูลงาน กับข้อมูลตารางเรียน

    final prompt = """
คุณคือผู้ช่วยจัดการตารางเรียน และงานของผู้ใช้ในแอปชื่อ School Day พัฒนาโดยนักเรียนโรงเรียนอำนาจเจริญ

หน้าที่ของคุณคือ:
- วิเคราะห์คำสั่งของผู้ใช้ที่เกี่ยวข้องกับการจัดการ "งาน" (Todo) หรือ "ตารางเรียน" (Timetable)
- ตอบกลับเป็น JSON แบบ plain text เท่านั้น ห้ามมีส่วนอื่นประกอบ (ไม่ต้องอธิบายหรือสนทนา)
- ทำความเข้าใจภาษาไทยแบบธรรมชาติ เช่น "พรุ่งนี้มีสอบคณิตตอน 8 โมงที่ห้อง 302"
- อย่าตอบเกินกว่าที่ระบบร้องขอ เช่น ห้ามพูดคุยอธิบายเพิ่ม
- ให้ใส่ฟิลด์ "replyText" เพื่อใช้แสดงข้อความตอบกลับผู้ใช้ โดยสรุปสิ่งที่ระบบได้เข้าใจ เช่น "เพิ่มคาบเรียนวิทยาศาสตร์แล้ว" หรือ "เพิ่มงานสอบชีวะตอน 9 โมงแล้ว"

ตัวอย่างรูปแบบ JSON ที่คุณต้องตอบกลับ มี 2 แบบ:

หากเป็นงาน (Todo):
{
  "type": "todo",
  "action": "add" || "update" || "delete",
  "title": String,
  "priority": "high" || "medium" || "low" || null,
  "description": String || null,
  "alarmTime": ISO8601 Date || null // หากผู้ใช้ไม่ได้บอกเวลาที่ชัดเจน ให้ถือว่าเป็น 8:00
}

หากเป็นตารางเรียน (Timetable):
{
  "type": "timetable",
  "action": "add" || "update" || "delete",
  "title": String,
  "startTime": ISO8601 Date || null,
  "endTime": ISO8601 Date || null,
  "location": String,
  "professor": String,
  "isNotify": true || false,
  "notifyTime": ISO8601 Date || null
}

ให้ใส่งานทั้งหมดไว้ใน "tasks" แบบนี้ แต่ถ้าไม่มีการเกี่ยวข้องกับงาน หรือตารางเรียนให้ "tasks" เป็น null:
{
  "type": "normal",
  "replyText": String // ให้ตอบกลับคำขอของผู้ใช้งาน,
  "tasks": [...] || null,
}

วันนี้คือ:
${DateTime.now().toIso8601String()}

คำสั่งของผู้ใช้:
$userMessage

กรุณาตอบกลับเฉพาะ JSON ตามที่กำหนดด้านบนเท่านั้น และเป็น null ได้เฉพาะที่กำหนดเท่านั้น
""";

    final body = jsonEncode({
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    try {
      if (response.statusCode != 200) {
        throw Exception('เกิดข้อผิดพลาดจาก Gemini API: ${response.body}');
      }

      final decoded = jsonDecode(response.body);
      final content =
          decoded['candidates'][0]['content']['parts'][0]['text'] ?? '';

      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) {
        throw Exception('ไม่พบ JSON ในคำตอบของ AI');
      }

      final jsonString = content.substring(jsonStart, jsonEnd + 1);
      final jsonData = jsonDecode(jsonString);

      if (!isValidResponse(jsonData)) {
        throw Exception('รูปแบบ JSON ไม่ถูกต้อง: $jsonData');
      }

      return jsonData;
    } catch (e) {
      debugPrint(e.toString());

      return {
        'type': 'error',
        'replyText': 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
        'tasks': null,
      };
    }
  }

  static bool isValidResponse(Map<String, dynamic> json) {
    if (!json.containsKey('type') || !json.containsKey('replyText')) {
      return false;
    }

    final type = json['type'];
    if (type == 'todo') {
      return json.containsKey('title') &&
          json.containsKey('priority') &&
          json.containsKey('alarmTime');
    } else if (type == 'timetable') {
      return json.containsKey('title') &&
          json.containsKey('startTime') &&
          json.containsKey('endTime') &&
          json.containsKey('location') &&
          json.containsKey('professor') &&
          json.containsKey('notifyTime');
    } else if (type == 'normal') {
      return json.containsKey('tasks') &&
          (json['tasks'] == null || json['tasks'] is List);
    } else {
      return false;
    }
  }
}
