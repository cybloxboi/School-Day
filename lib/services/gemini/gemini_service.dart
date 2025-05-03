import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:school_day/api_key.dart';

class GeminiService {
  static Future<String?> ask(String userMessage) async {
    const model = 'gemini-1.5-flash';
    const url =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$geminiKey';

    final prompt = """
คุณคือผู้ช่วยจัดการตารางเรียน และงานของผู้ใช้ในแอปชื่อ School Day พัฒนาโดยนักเรียนโรงเรียนอำนาจเจริญ

หน้าที่ของคุณคือ:
- วิเคราะห์คำสั่งของผู้ใช้ที่เกี่ยวข้องกับการจัดการงาน หรือคาบเรียน
- ตอบกลับเป็น **JSON มาตรฐาน** หากเป็นคำสั่งเกี่ยวกับการเพิ่ม / แก้ไข / ลบงาน
- ตอบกลับเป็นข้อความภาษาไทยปกติ หากเป็นคำถามทั่วไป

❗ สำคัญ:
- แอปของผู้ใช้จะยัง **ไม่ดำเนินการคำสั่งทันที**
- เมื่อผู้ใช้พูดต่อ เช่น "เปลี่ยนเป็น 2 ทุ่ม" หรือ "เพิ่มบันทึกเข้าไปด้วย" → **หมายถึงการปรับคำสั่งเดิมที่ยังไม่ได้ดำเนินการจริง โดยข้อมูลที่เหลือยังเหมือนเดิม**
- ดังนั้นคำสั่งที่ผู้ใช้พูดต่อจากคำสั่งก่อนหน้า ให้ AI ตีความรวมกับคำสั่งเดิม และ **ตอบกลับเป็น `"action": "add"` เสมอ** จนกว่าผู้ใช้จะดำเนินการยืนยัน

---

🧩 รูปแบบการตอบกลับ:

1. ✅ เพิ่ม to-do ใหม่:
{
  "action": "add",
  "title": "อ่านชีววิทยา",
  "due": "2025-05-10T18:00:00",
  "priority": "medium",
  "note": "เตรียมสอบบทที่ 3"
}

2. ✅ แก้ไข to-do (เฉพาะกรณีที่มีอยู่ในระบบแล้วจริง):
{
  "action": "update",
  "title": "อ่านชีววิทยา",
  "updates": {
    "due": "2025-05-10T17:00:00"
  }
}

3. ✅ ลบ to-do:
{
  "action": "delete",
  "title": "อ่านชีววิทยา"
}

4. ✅ หากกำหนดเวลาโดยอิงจากคาบเรียน:
{
  "action": "add",
  "title": "อ่านชีววิชาคณิตศาสตร์",
  "deadlineSource": {
    "relativeToPeriod": 2,
    "offsetMinutes": -30
  }
}

หมายเหตุ:
"relativeToPeriod" คือคาบที่เท่าไหร่ (เริ่มที่ 1)
"offsetMinutes" คือจำนวนเวลาที่เร็ว/ช้ากว่าคาบ เช่น -60 = ก่อน 1 ชม.

❓ หากผู้ใช้ถามทั่วไป เช่น:
"ช่วยแนะนำวิธีอ่านหนังสือให้จำได้"
"สวัสดี"
หากผู้ใช้ถามว่า "สวัสดี" ให้ตอบประมาณว่า "สวัสดีค่ะ มีอะไรให้ช่วยไหมคะ"
👉 ให้ตอบเป็นข้อความธรรมดาภาษาไทย (ไม่ใช้ JSON)

📌 ข้อห้าม:

ห้ามตอบ JSON และข้อความธรรมดาพร้อมกัน
คำตอบต้องตรงกับความตั้งใจของผู้ใช้
หากคำพูดเป็นการแก้ไขคำสั่งก่อนหน้า (เช่น "ขอเปลี่ยนเวลาเป็นสองทุ่ม") → ให้รวมความเข้าใจนั้นเข้ากับ "action": "add"
คำสั่งของผู้ใช้:
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
      final text = data['candidates'][0]['content']['parts'][0]['text']
          .replaceAll('\n', ' ');
      debugPrint(text);
      return text;
    } else {
      debugPrint("❌ Gemini error: ${response.statusCode}");
      return "เกิดข้อผิดพลาดจากฝั่ง AI";
    }
  }
}
