import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_day/styles/styles.dart';

class AboutDeveloper extends StatefulWidget {
  const AboutDeveloper({super.key});

  @override
  State<AboutDeveloper> createState() => _AboutDeveloperState();
}

class _AboutDeveloperState extends State<AboutDeveloper> {
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
