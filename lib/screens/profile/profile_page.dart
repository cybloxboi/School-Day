import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:school_day/screens/profile/edit_profile_page.dart';
import 'package:school_day/screens/report/report_problem_page.dart';
import 'package:school_day/services/database/user/user_document.dart';
import 'package:school_day/styles/styles.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final User? user;
  late UserDocument userDocument;
  late final Stream<DocumentSnapshot> _userStream;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    userDocument = UserDocument(FirebaseAuth.instance.currentUser!.email!);
    _userStream = userDocument.getUserDocumentSnapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ฉัน',
          style: textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FutureBuilder(
            future: getCurrentUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.data == null) {
                return Center(
                  child: LoadingAnimationWidget.fourRotatingDots(
                    color: primaryColor,
                    size: 80,
                  ),
                );
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    spacing: 8,
                    children: [
                      StreamBuilder(
                        stream: userDocument.getUsername(_userStream),
                        builder: (context, username) {
                          return Column(
                            spacing: 16,
                            children: [
                              Text(
                                'สวัสดี, ${username.data}',
                                style: textTheme.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.contain,
                                child: ClipOval(
                                  child: CircleAvatar(
                                    radius: 64,
                                    child: snapshot.data!.photoURL != null
                                        ? CachedNetworkImage(
                                            imageUrl: snapshot.data!.photoURL!,
                                            placeholder: (context, url) {
                                              return LoadingAnimationWidget
                                                  .beat(
                                                color: primaryColor,
                                                size: 80,
                                              );
                                            },
                                          )
                                        : Image.asset(
                                            'assets/images/blank_profile.jpg'),
                                  ),
                                ),
                              ),
                              const Divider(),
                              Text(
                                'รายละเอียดโปรไฟล์',
                                style: textTheme.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.start,
                              ),
                              ListTile(
                                leading: const Icon(Icons.email),
                                title: Text(snapshot.data!.email!),
                              ),
                              ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(username.data.toString()),
                              ),
                              FilledButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProfilePage(
                                        username: username.data,
                                        email: snapshot.data!.email!,
                                      ),
                                    ),
                                  );
                                },
                                label: const Text('แก้ไขข้อมูล'),
                                icon: const Icon(Icons.edit_rounded),
                              ),
                              const Divider(),
                              Text(
                                'การแจ้งเตือน',
                                style: textTheme.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.start,
                              ),
                              SwitchListTile(
                                value: false,
                                onChanged: (value) {},
                                title: Text(
                                  'เปิด/ปิดการแจ้งเตือนตารางเรียน',
                                  style: textTheme.bodySmall,
                                ),
                              ),
                              const Divider(),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ReportProblemPage(),
                                    ),
                                  );
                                },
                                label: Text(
                                  'รายงานปัญหาที่พบ',
                                  style: textTheme.bodySmall!
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                                icon: const Icon(Icons.report_problem_rounded),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.groups_rounded),
                                label: Text(
                                  'เกี่ยวกับผู้พัฒนา และแอปพลิเคชัน',
                                  style: textTheme.bodySmall!
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                        'เกี่ยวกับแอปพลิเคชัน',
                                        style: textTheme.bodyMedium!.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          spacing: 16,
                                          children: [
                                            Text(
                                              'แอปนี้ถูกพัฒนาโดย',
                                              style:
                                                  textTheme.bodySmall!.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '1. นายศุกลณัฏฐ์ ถาวรฟัง ม.5/11\n2. นางสาวศุภิสรา ศิริอำนาจ ม.5/6\n3. นายวชิรวิทย์ บุตตะโคตร ม.5/6',
                                              style: textTheme.bodySmall,
                                            ),
                                            Text(
                                              'โรงเรียนอำนาจเจริญ',
                                              style: textTheme.bodySmall,
                                            ),
                                            const Divider(),
                                            Text(
                                              'จุดประสงค์ของแอปนี้',
                                              style:
                                                  textTheme.bodySmall!.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'เพื่อสร้างแอปพลิเคชันที่สามารถช่วยให้นักเรียนบริหารจัดการตารางเรียนและงานต่าง ๆ ได้อย่างเป็นระบบ ช่วยลดความสับสนในการจัดสรรเวลา พร้อมทั้งเพิ่มความคล่องตัวในการติดตามงานหรือกิจกรรมที่ต้องทำในแต่ละวัน โดยมุ่งเน้นให้การใช้งานเป็นไปอย่างสะดวก เข้าใจง่าย และสามารถตอบสนองต่อความต้องการของผู้เรียนในยุคดิจิทัลที่เทคโนโลยีเข้ามามีบทบาทในชีวิตประจำวันมากยิ่งขึ้น',
                                              style: textTheme.bodySmall,
                                            ),
                                            const Divider(),
                                            Text(
                                              'เวอร์ชัน 1.3.0',
                                              style:
                                                  textTheme.bodySmall!.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
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
                                                builder: (context) =>
                                                    const LicensePage(
                                                  applicationName: 'School Day',
                                                  applicationVersion: '1.3.0',
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('ปิด'),
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              Text(
                                'เวอร์ชัน 1.3.0',
                                style: textTheme.bodySmall,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<User?> getCurrentUser() async {
    await FirebaseAuth.instance.currentUser?.reload();
    return FirebaseAuth.instance.currentUser;
  }
}
