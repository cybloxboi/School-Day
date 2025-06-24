import 'package:flutter/material.dart';
import 'package:school_day/styles/styles.dart';

class PrivacyPolicyButton extends StatelessWidget {
  const PrivacyPolicyButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Text(
        'นโยบายความเป็นส่วนตัว',
        style: textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const PrivacyPolicy(),
        );
      },
    );
  }
}

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(
        'นโยบายความเป็นส่วนตัว',
        style: textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
        ),
        child: Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ปรับปรุงล่าสุด: 23 มิถุนายน 2568'),
            Text(
                'แอปพลิเคชัน "School Day" (ต่อไปนี้เรียกว่า "แอปฯ") เคารพในสิทธิความเป็นส่วนตัวของผู้ใช้งาน'),
            Text(
              '1. ข้อมูลที่แอปฯ เก็บรวบรวม',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('เมื่อผู้ใช้งานใช้บริการ แอปฯ จะเก็บข้อมูลต่อไปนี้'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• '),
                Expanded(
                  child: Text(
                    'ข้อมูลบัญชีผู้ใช้: อีเมล ชื่อผู้ใช้ รหัสผ่านที่เชื่อมกับ Firebase Authentication',
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• '),
                Expanded(
                  child: Text(
                    'ข้อมูลการใช้งาน: ตารางเรียน ข้อมูลงาน คำสั่งที่ผู้ใช้ส่งถึงระบบ School Day AI',
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• '),
                Expanded(
                  child: Text(
                    'ข้อมูลอุปกรณ์: ประเภทอุปกรณ์ ระบบปฏิบัติการ และรหัสอุปกรณ์สำหรับการแจ้งเตือน (Device ID)',
                  ),
                ),
              ],
            ),
            Text(
              '2. วัตถุประสงค์ในการใช้ข้อมูล',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('แอปฯ ใช้ข้อมูลที่เก็บเพื่อวัตถุประสงค์ต่อไปนี้'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• '),
                Expanded(
                  child: Text(
                    'เพื่อแสดงและจัดการตารางเรียน และงานของผู้ใช้',
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• '),
                Expanded(
                  child: Text(
                    'เพื่อวิเคราะห์คำสั่งของผู้ใช้ผ่านระบบ School Day AI และให้คำตอบอัตโนมัติ',
                  ),
                ),
              ],
            ),
            Text(
              '3. การแบ่งปันข้อมูลกับบุคคลภายนอก',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• '),
                Expanded(
                  child: Text(
                      'ข้อมูลตารางเรียน และงานอาจถูกส่งไปยังระบบปัญญาประดิษฐ์ (AI) ของบุคคลที่สาม ให้แก่ Google Gemini เพื่อวิเคราะห์คำสั่งของผู้ใช้ตามที่ร้องขอ'),
                ),
              ],
            ),
            Text(
              '4. สิทธิของผู้ใช้',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• '),
                Expanded(
                  child: Text(
                    'ถอนความยินยอมในการใช้ข้อมูลบางประเภท เช่น ปิดการใช้ School Day AI',
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• '),
                Expanded(
                  child: Text(
                    'ลบบัญชีผู้ใช้และข้อมูลทั้งหมดในระบบได้ตามต้องการ',
                  ),
                ),
              ],
            ),
            Text(
                'หากต้องการดำเนินการดังกล่าว กรุณาติดต่อผู้พัฒนาตามข้อมูลในข้อ 7'),
            Text(
              '5. การเก็บรักษาข้อมูล',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• '),
                Expanded(
                  child: Text(
                    'เมื่อผู้ใช้ลบบัญชี ข้อมูลการเข้าสู่ระบบ และข้อมูลภายในระบบทั้งหมดจะถูกลบออกจากระบบ',
                  ),
                ),
              ],
            ),
            Text(
              '6. การเปลี่ยนแปลงนโยบายนี้',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'แอปฯ ขอสงวนสิทธิ์ในการแก้ไขหรือเปลี่ยนแปลงนโยบายความเป็นส่วนตัวนี้ได้โดยไม่ต้องแจ้งให้ทราบล่วงหน้า',
            ),
            Text(
              '7. การติดต่อ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'หากผู้ใช้งานมีคำถาม ข้อเสนอแนะ หรือข้อร้องเรียนใด ๆ สามารถติดต่อทีมผู้พัฒนาได้ทาง\nอีเมล: 44884@anc.ac.th',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('ปิด'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
