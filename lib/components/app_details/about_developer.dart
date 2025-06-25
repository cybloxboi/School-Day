import 'package:flutter/material.dart';
import 'package:school_day/styles/styles.dart';

class AboutDeveloper extends StatelessWidget {
  const AboutDeveloper({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Row(
        spacing: 16,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 50,
              height: 50,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(
                'เกี่ยวกับแอปพลิเคชัน',
                style: textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'เวอร์ชัน $appVersion',
                style: textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Text(
              'แอปนี้ถูกพัฒนาด้วย Flutter & Firebase & Gemini โดย',
              style: textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '1. นายศุกลณัฏฐ์ ถาวรฟัง ม.5/11\n2. นางสาวศุภิสรา ศิริอำนาจ ม.5/6\n3. นายวชิรวิทย์ บุตตะโคตร ม.5/6',
              style: textTheme.bodySmall,
            ),
            Text(
              'โรงเรียนอำนาจเจริญ โดยมี นางสาว อารีรัตน์ ธานี เป็นคุณครูที่ปรึกษาโครงการ',
              style: textTheme.bodySmall,
            ),
            const Divider(),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('แสดงใบอนุญาต'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LicensePage(
                  applicationName: 'School Day',
                  applicationVersion: appVersion,
                  applicationIcon: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        TextButton(
          child: const Text('ปิด'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
