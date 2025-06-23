import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:school_day/api_key.dart';

dynamic makeEncodable(dynamic value) {
  if (value is Timestamp) {
    return value.toDate().toIso8601String();
  } else if (value is Map) {
    return value.map((k, v) => MapEntry(k, makeEncodable(v)));
  } else if (value is List) {
    return value.map(makeEncodable).toList();
  }
  return value;
}

class GeminiService {
  static Future<Map<String, dynamic>> ask({
    required String userMessage,
    required String email,
  }) async {
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiKey';

    // TODO: รับข้อมูลตารางเรียน
    final firestore = FirebaseFirestore.instance;
    final todosSnapshot = await firestore
        .collection('Users')
        .doc(email)
        .collection('Todos')
        .get();

    final rawTodos = todosSnapshot.docs.map((doc) => doc.data()).toList();

    final todos = makeEncodable(rawTodos);

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
  "oldTodo": {
    ... // เหมือนกันกับ "newTodo"
  } || null, // หากเป็นการ update ให้แนบค่า oldTodo ในนี้
  "newTodo": { // หากเป็น add ให้เอามาจากคำสั่งผู้ใช้ แต่ถ้าเป็น delete ให้แนบมาได้เลย
    "id": String || null, // ให้แนบมาหากเป็น delete
    "title": String,
    "priority": "high" || "medium" || "low" || "none",
    "description": String || null,
    "alarmTime": ISO8601 Date || null // หากผู้ใช้ไม่ได้บอกเวลาที่ชัดเจน เช่นแค่วันที่ ให้ถือว่าเป็น 8:00
  }
}

หากเป็นตารางเรียน (Timetable):
{
  "type": "timetable",
  "action": "add" || "update" || "delete",
  "oldTimetable": {
    ... // เหมือนกันกับ "newTodo"
  } || null, // หากเป็นการ update ให้แนบค่า oldTodo ในนี้
  "newTimetable": { // หากเป็น add ให้เอามาจากคำสั่งผู้ใช้ แต่ถ้าเป็น delete ให้แนบมาได้เลย
    "id": String || null, // ให้แนบมาหากเป็น delete
    "title": String,
    "startTime": ISO8601 Date || null,
    "endTime": ISO8601 Date || null,
    "location": String,
    "professor": String,
    "isNotify": true || false,
    "notifyTime": ISO8601 Date || null
  }
}

ให้ใส่ทั้งหมดไว้ใน "tasks" แบบนี้ แต่ถ้าไม่มีการเกี่ยวข้องกับงาน หรือตารางเรียนให้ "tasks" เป็น null:
{
  "status": "normal",
  "replyText": String // ให้ตอบกลับคำขอของผู้ใช้งาน,
  "tasks": [...] || null,
}

วันนี้คือ:
${DateTime.now().toIso8601String()}

ข้อมูลงาน (todos) ปัจจุบันของผู้ใช้:
${jsonEncode(todos)}

คำสั่งของผู้ใช้:
$userMessage

กรุณาตอบกลับเฉพาะ JSON ตามที่กำหนดด้านบนเท่านั้น และเป็น null ได้เฉพาะที่กำหนดเท่านั้น

แต่ถ้าไม่พบข้อมูลที่ผู้ใช้ต้องการ ให้คืนค่า
{
  "status": "error",
  "replyText": // บอกเหตุผลผู้ใช้งาน,
  "tasks": null,
}
""";

    debugPrint(prompt);

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

      if (!isValidTask(jsonData)) {
        throw Exception('รูปแบบ JSON ไม่ถูกต้อง: $jsonData');
      }

      return jsonData;
    } catch (e) {
      debugPrint(e.toString());

      return {
        'status': 'error',
        'replyText': 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
        'tasks': null,
      };
    }
  }

  static bool isValidTask(Map<String, dynamic> json) {
    if (!json.containsKey('status') ||
        !json.containsKey('replyText') ||
        !json.containsKey('tasks')) {
      return false;
    }

    final tasks = json['tasks'];

    if (tasks != null) {
      if (tasks is! List) return false;

      for (final task in tasks) {
        if (task is! Map<String, dynamic>) return false;

        if (!task.containsKey('type') || !task.containsKey('action')) {
          return false;
        }

        final type = task['type'];
        if (type == 'todo') {
          final newTodo = task['newTodo'];
          if (newTodo == null || !newTodo.containsKey('title')) return false;
        } else if (type == 'timetable') {
          final newTimetable = task['newTimetable'];
          if (newTimetable == null ||
              !newTimetable.containsKey('title') ||
              !newTimetable.containsKey('startTime') ||
              !newTimetable.containsKey('endTime') ||
              !newTimetable.containsKey('location') ||
              !newTimetable.containsKey('professor') ||
              !newTimetable.containsKey('isNotify') ||
              !newTimetable.containsKey('notifyTime')) {
            return false;
          }
        } else {
          return false;
        }
      }
    }

    return true;
  }
}
