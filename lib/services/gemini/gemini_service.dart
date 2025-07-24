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
    required String categoryId,
    required String timetableId,
  }) async {
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiKey';

    final firestore = FirebaseFirestore.instance;
    final todosSnapshot = await firestore
        .collection('Users')
        .doc(email)
        .collection('Todos')
        .doc(categoryId)
        .get();

    dynamic todo;

    if (todosSnapshot.exists) {
      final rawTodo = todosSnapshot.data();
      todo = makeEncodable(rawTodo);
    }

    final timetableSnapshot = await firestore
        .collection('Users')
        .doc(email)
        .collection('Timetables')
        .doc(timetableId)
        .get();

    dynamic timetable;
    if (timetableSnapshot.exists) {
      final rawTimetable = timetableSnapshot.data();
      timetable = makeEncodable(rawTimetable);
    }

    final prompt = """
คุณคือผู้ช่วยจัดการตารางเรียน และงานของผู้ใช้ในแอปชื่อ School Day พัฒนาโดยนักเรียนโรงเรียนอำนาจเจริญ

หน้าที่ของคุณคือ:

วิเคราะห์คำสั่งของผู้ใช้ที่เกี่ยวข้องกับการจัดการ "งาน" (Todo) หรือ "ตารางเรียน" (Timetable)
ตอบกลับเป็น JSON แบบ plain text เท่านั้น
รองรับ ภาษาไทยธรรมชาติ เช่น "พรุ่งนี้มีสอบคณิตตอน 8 โมงที่ห้อง 302" หรือ "ลบงานอ่านหนังสือออก"
ถ้าคำสั่ง เกี่ยวข้องกับงานหรือคาบเรียน ให้ระบุใน tasks เป็น array ของรายการที่เข้าใจได้ในรูปแบบ JSON ตามโครงสร้างด้านล่าง
ถ้าคำสั่งเป็น การถามทั่วไป หรือไม่ได้สั่งให้เพิ่ม/ลบ/แก้ไข เช่น "วันนี้มีเรียนอะไรบ้าง" ให้ตอบใน replyText และให้ tasks: null
ถ้าพบว่า ข้อมูลไม่ครบถ้วน หรือไม่เข้าใจคำสั่ง ให้ตอบ status: "error" พร้อมเหตุผลใน replyText
รูปแบบ JSON ที่ต้องส่งกลับ:
{
  "status": "normal" || "error",
  "replyText": "...", // ตอบกลับสั้น ๆ ว่าเข้าใจว่าอย่างไร หรือสรุปผล
  "tasks": [...] || null // รายการงานหรือตารางเรียนที่เข้าใจได้ (หากมี)
}
โครงสร้าง tasks:
ถ้าเป็น "งาน" (Todo):

{
  "type": "todo",
  "action": "add" || "update" || "delete",
  "oldTodo": { ... } || null,
  "newTodo": {
    "id": String || null,
    "title": String,
    "priority": "high" || "medium" || "low" || "none",
    "description": String || null,
    "selectedDate": ISO8601 Date || null,
    "alarmTime": {
      "hour": int,
      "minute": int
    } || null
  }
}
ถ้าเป็น "ตารางเรียน" (Timetable):

{
  "type": "timetable",
  "action": "add" || "update" || "delete",
  "oldTimetable": { ... } || null,
  "newTimetable": {
    "id": String || null,
    "dateIndex": 0 - 6, // 0 = จันทร์, 6 = อาทิตย์
    "date": "วันจันทร์" ถึง "วันอาทิตย์",
    "title": String,
    "startTime": {
      "hour": int,
      "minute": int
    },
    "endTime": {
      "hour": int,
      "minute": int
    },
    "location": String,
    "professor": String
  }
}
หากคำสั่ง ไม่เกี่ยวข้องกับการจัดการข้อมูล ให้ใส่ "tasks": null แล้วตอบใน "replyText" ได้ตามปกติ เช่น:

{
  "status": "normal",
  "replyText": "แอป School Day คือแอปสำหรับจัดการตารางเรียนและงานของนักเรียนโดยเฉพาะ",
  "tasks": null
}
หาก ข้อมูลไม่ครบถ้วน หรือสั่งให้เพิ่ม แต่ไม่บอกชื่อวิชา เวลา หรืออื่น ๆ:

{
  "status": "error",
  "replyText": "ขออภัย ไม่สามารถเพิ่มคาบเรียนได้ เนื่องจากคุณยังไม่ได้ระบุชื่อวิชา",
  "tasks": null
}

ตัวแปรที่จะถูกแทนก่อนประมวลผล:
วันนี้คือ: ${DateTime.now().toIso8601String()}
ข้อมูลงาน (todos) ปัจจุบันของผู้ใช้: ${todo != null ? jsonEncode(todo) : "ไม่มีงาน"}
ข้อมูลตารางเรียน (timetable) ปัจจุบันของผู้ใช้: ${timetable != null ? jsonEncode(timetable) : "ไม่มีตารางเรียน"}
คำสั่งของผู้ใช้: $userMessage

โปรดอธิบายรายละเอียดอย่างชัดเจน และตอบกลับข้อมูลให้ครบถ้วนตามรูปแบบ JSON ที่กำหนด
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

      debugPrint(jsonString);

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
              !newTimetable.containsKey('dateIndex')) {
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
