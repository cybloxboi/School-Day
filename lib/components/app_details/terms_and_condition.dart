import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_day/styles/styles.dart';

class TermsAndConditionButton extends StatelessWidget {
  const TermsAndConditionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Text(
        'ข้กตกลงและเงื่อนไขการใช้งาน',
        style: textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const TermsAndCondition(),
        );
      },
    );
  }
}

class TermsAndCondition extends StatefulWidget {
  const TermsAndCondition({super.key});

  @override
  State<TermsAndCondition> createState() => _TermsAndConditionState();
}

class _TermsAndConditionState extends State<TermsAndCondition> {
  String _licenseAgreementText = '';

  @override
  void initState() {
    super.initState();

    loadTextFromFile(
      'assets/texts/license_agreement.txt',
      (text) => setState(
        () {
          _licenseAgreementText = text;
        },
      ),
    );
  }

  Future<void> loadTextFromFile(
      String path, void Function(String) onLoad) async {
    final text = await rootBundle.loadString(path);
    onLoad(text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(
        'ข้อตกลงและเงื่อนไขการใช้งาน',
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
            Text('ปรับปรุงล่าสุด: 24 มิถุนายน 2568'),
            Text(
                'โปรดอ่านข้อตกลงและเงื่อนไขการใช้งานนี้อย่างละเอียดก่อนเริ่มใช้งานแอปพลิเคชัน "School Day" (ต่อไปนี้เรียกว่า "แอปฯ")'),
            Text(
                'เมื่อผู้ใช้งานให้ความยินยอมข้อตกลงและเงื่อนไขในการใช้งานในขั้นตอนการสมัครสมาชิกของแอปฯ จะถือว่าผู้ใช้งานได้อ่าน เข้าใจ และยอมรับข้อกำหนดต่าง ๆ ที่ระบุไว้ในข้อตกลงนี้แล้วโดยสมบูรณ์'),
            Text(
              'ข้อตกลงในการใช้งานซอฟต์แวร์',
              style: textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '     '),
                  TextSpan(text: _licenseAgreementText),
                ],
              ),
              textAlign: TextAlign.start,
              style: textTheme.bodySmall,
            ),
            Text(
              '1. วัตถุประสงค์ของแอปพลิเคชัน',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
                'แอป School Day เป็นแอปเพื่อการศึกษาและจัดการเวลา ใช้ในการจัดตารางเรียน บันทึกงาน กำหนดการ และวิเคราะห์ข้อมูลด้วยระบบปัญญาประดิษฐ์ (AI) เพื่อช่วยให้ผู้ใช้งานบริหารจัดการเวลาและการเรียนรู้ได้อย่างมีประสิทธิภาพ'),
            Text(
              '2. การเก็บและใช้ข้อมูลของผู้ใช้',
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
                    'แอปฯ จะทำการเก็บข้อมูลที่จำเป็นต่อการให้บริการ เช่น อีเมล ตารางเรียน ข้อมูลงาน รายละเอียดที่ผู้ใช้กรอก รวมถึงคำสั่งที่ผู้ใช้ป้อนเข้าสู่ระบบ AI',
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
                      'ข้อมูลดังกล่าวจะถูกจัดเก็บอย่างปลอดภัยบนระบบฐานข้อมูล Firestore โดยใช้มาตรฐานการรักษาความปลอดภัยของ Google Cloud'),
                ),
              ],
            ),
            Text(
              '3. การใช้ข้อมูลร่วมกับระบบ AI',
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
                      'แอปฯ มีฟีเจอร์ "School Day AI" ซึ่งเป็นระบบผู้ช่วยอัจฉริยะในการจัดตารางเรียนและงานของผู้ใช้ โดยการวิเคราะห์คำสั่งของผู้ใช้'),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• '),
                Expanded(
                  child: Text(
                      'เมื่อผู้ใช้ใช้งานฟีเจอร์นี้ ระบบจะทำการส่งข้อมูลที่เกี่ยวข้องกับคำสั่ง เช่น ตารางเรียน งานที่เคยมี หรือคำพูดของผู้ใช้ ไปยังระบบปัญญาประดิษฐ์ (AI) เพื่อประมวลผลและแสดงผลลัพธ์กลับมา'),
                ),
              ],
            ),
            Text(
              '4. ความปลอดภัยของข้อมูล',
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
                    'แอปฯ มีมาตรการรักษาความปลอดภัยในการจัดเก็บข้อมูล และใช้ Firebase Authentication เพื่อระบุตัวตนผู้ใช้งาน',
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
                    'อย่างไรก็ตาม ผู้พัฒนาไม่สามารถรับประกันได้อย่างสมบูรณ์ว่าจะไม่มีเหตุการณ์ด้านความปลอดภัยเกิดขึ้น จึงขอให้ผู้ใช้งานใช้ความระมัดระวังและไม่เปิดเผยข้อมูลส่วนตัวของตนเองโดยไม่จำเป็น',
                  ),
                ),
              ],
            ),
            Text(
              '5. การเปลี่ยนแปลงเงื่อนไข',
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
                    'ผู้พัฒนาขอสงวนสิทธิ์ในการเปลี่ยนแปลง แก้ไข หรือปรับปรุงข้อตกลงและเงื่อนไขการใช้งานฉบับนี้ได้ตามความเหมาะสม โดยไม่จำเป็นต้องกล่าวให้ทราบล่วงหน้า',
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
                    'การใช้งานต่อเนื่องหลังจากมีการเปลี่ยนแปลง จะถือว่าผู้ใช้งานยอมรับเงื่อนไขที่แก้ไขแล้วโดยอัตโนมัติ',
                  ),
                ),
              ],
            ),
            Text(
              '6. การยุติการให้บริการและการลบบัญชี',
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
                    'ผู้ใช้งานสามารถเลือกยุติการใช้บริการหรือลบบัญชีผู้ใช้งานของตนได้ทุกเมื่อ โดยข้อมูลที่เกี่ยวข้องจะถูกลบออกจากฐานข้อมูล',
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
                    'ผู้พัฒนาขอสงวนสิทธิ์ในการระงับหรือยุติการให้บริการแอปฯ ชั่วคราวหรือถาวรโดยไม่จำเป็นต้องแจ้งให้ทราบล่วงหน้า',
                  ),
                ),
              ],
            ),
            Text(
                'หากต้องการดำเนินการดังกล่าว กรุณาติดต่อผู้พัฒนาตามข้อมูลในข้อ 7'),
            Text(
              '7. ติดต่อสอบถาม',
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
