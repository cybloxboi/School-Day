import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:school_day/api_key.dart';

class GeminiService {
  static Future<Map<String, dynamic>> ask(String userMessage) async {
    const model = 'gemini-1.5-flash';
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$geminiKey';

    final prompt = """
คุณคือผู้ช่วยจัดการตารางเรียน และงานของผู้ใช้ในแอปชื่อ School Day พัฒนาโดยนักเรียนโรงเรียนอำนาจเจริญ

หน้าที่ของคุณคือ:
- วิเคราะห์คำสั่งของผู้ใช้ที่เกี่ยวข้องกับการจัดการงาน หรือคาบเรียน
- ตอบกลับเป็น **JSON มาตรฐาน** หากเป็นคำสั่งเกี่ยวกับการเพิ่ม / แก้ไข / ลบงาน
- ตอบกลับเป็นข้อความภาษาไทยปกติ หากเป็นคำถามทั่วไป

คำตอบต้องอยู่ในรูปแบบ JSON เสมอ และมีโครงสร้างแบบนี้:

{
  "responseText": "ข้อความตอบกลับภาษาไทยเพื่อพูดคุยกับผู้ใช้ เช่น สวัสดีค่ะ มีอะไรให้ช่วยไหมคะ",
  "tasks": [ ... ] // หรือ null หากไม่เกี่ยวข้องกับงาน
}

รูปแบบของ tasks แต่ละรายการ (เฉพาะกรณีที่เกี่ยวข้องกับงาน):
- เพิ่มงานใหม่:
  {
    "action": "add",
    "title": "ชื่อของงาน",
    "due": "ISO8601 datetime หรือ null",
    "priority": "low" | "medium" | "high" หรือ null,
    "note": "รายละเอียดเพิ่มเติม" หรือ null
  }

- แก้ไขงาน:
  {
    "action": "update",
    "title": "ชื่อของงานที่จะแก้ไข",
    "updates": {
      "due": "...",
      "priority": "...",
      "note": "..."
    }
  }

- ลบงาน:
  {
    "action": "delete",
    "title": "ชื่อของงานที่ต้องการลบ"
  }

- หากงานอิงจากคาบเรียน:
  {
    "action": "add",
    "title": "อ่านชีววิชาคณิตศาสตร์",
    "deadlineSource": {
      "relativeToPeriod": 2,
      "offsetMinutes": -30
    }
  }

ข้อบังคับสำคัญ:
- ต้องมี `responseText` เสมอ
- `tasks` ต้องเป็น array หรือ `null` เท่านั้น
- ห้ามส่งข้อความนอก JSON
- ตอบกลับเป็น **JSON เท่านั้น** โดยไม่มีเครื่องหมาย ``` หรือ markdown ใด ๆ
- ห้ามใส่ ```json, ``` หรือข้อความนอก JSON เด็ดขาด
- ให้ส่งแค่ JSON บริสุทธิ์ (pure JSON string) เท่านั้น
- โครงสร้างต้องเริ่มต้นที่ `{` และจบที่ `}` เท่านั้น
- ห้ามใส่ข้อความอื่นนอกจากใน `responseText`
- วันที่วันนี้: "${DateTime.now().toIso8601String()}"

ตัวอย่าง:
หากผู้ใช้พิมพ์ "ช่วยเพิ่มงานอ่านหนังสือตอนสองทุ่มวันนี้"
→ ให้ตอบ:
{
  "responseText": "เพิ่มงานอ่านหนังสือให้แล้วค่ะ กำหนดเวลา 20:00 วันนี้",
  "tasks": [
    {
      "action": "add",
      "title": "อ่านหนังสือ",
      "due": "2025-05-04T20:00:00",
      "priority": null,
      "note": null
    }
  ]
}

หากผู้ใช้พิมพ์ "สวัสดี"
→ ให้ตอบ:
{
  "responseText": "สวัสดีค่ะ มีอะไรให้ช่วยไหมคะ",
  "tasks": null
}

เริ่มต้นวิเคราะห์คำพูดของผู้ใช้จากบรรทัดนี้:
"$userMessage"
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

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      try {
        final rawText = data['candidates'][0]['content']['parts'][0]['text'];
        final parsed = jsonDecode(rawText);

        if (parsed is Map &&
            parsed.containsKey('responseText') &&
            parsed.containsKey('tasks')) {
          return {
            "responseText": parsed['responseText'],
            "tasks": parsed['tasks'],
          };
        } else {
          debugPrint("⚠️ JSON ไม่ถูกต้อง ไม่มี key ที่ต้องการ");
          
          return {
            "responseText": "รูปแบบคำตอบจาก AI ไม่ถูกต้อง",
            "tasks": null,
          };
        }
      } catch (e) {
        debugPrint("❌ JSON Decode Error: $e");

        return {
          "responseText": "เกิดข้อผิดพลาดในการแปลงข้อมูลจาก AI",
          "tasks": null,
        };
      }
    } else {
      debugPrint("❌ Gemini error: ${response.statusCode}");

      return {
        "responseText": "เกิดข้อผิดพลาดจากฝั่ง AI",
        "tasks": null,
      };
    }
  }
}
