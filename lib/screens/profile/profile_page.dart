import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:school_day/components/others/check_latest_profile_image.dart';
import 'package:school_day/components/others/web_utils.dart';
import 'package:school_day/components/profile/notification_switch.dart';
import 'package:school_day/screens/profile/edit_profile_page.dart';
import 'package:school_day/screens/report/report_problem_page.dart';
import 'package:school_day/services/database/user/user_document.dart';
import 'package:school_day/styles/styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User? user;
  late UserDocument userDocument;
  late final Stream<DocumentSnapshot> _userStream;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    userDocument = UserDocument(user!.email!);
    _userStream = userDocument.getUserDocumentSnapshots();

    updateProfileImageUrl(user!);
  }

  Future logOut(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('fcm_token');
    final user = FirebaseAuth.instance.currentUser;

    if (token != null && user != null) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email!)
          .update(
        {
          'tokens': FieldValue.arrayRemove([token]),
          'platforms.$token': FieldValue.delete(),
        },
      );
    }

    await prefs.remove('fcm_token');

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ล็อคเอาท์สำเร็จ'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () => logOut(context),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                'ล็อคเอาท์',
                style: textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (user == null) {
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
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
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
                                        child: user!.photoURL != null
                                            ? CachedNetworkImage(
                                                imageUrl: user!.photoURL!,
                                                placeholder: (context, url) {
                                                  return LoadingAnimationWidget
                                                      .beat(
                                                    color: primaryColor,
                                                    size: 80,
                                                  );
                                                },
                                                errorWidget:
                                                    (context, url, error) {
                                                  return Image.asset(
                                                    'assets/images/blank_profile.jpg',
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
                                    title: Text(user!.email!),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.person),
                                    title: Text(username.data.toString()),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditProfilePage(
                                            username: username.data,
                                            email: user!.email!,
                                          ),
                                        ),
                                      );

                                      await FirebaseAuth.instance.currentUser
                                          ?.reload();

                                      setState(() {
                                        user =
                                            FirebaseAuth.instance.currentUser;
                                      });
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
                                  const NotificationSwitch(),
                                  const Divider(),
                                  TextButton.icon(
                                    onPressed: () {
                                      if (kIsWeb) {
                                        openNewTab(
                                          'https://forms.gle/ADrcqjmjCb5ocBr48',
                                          '_blank',
                                        );
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ReportProblemPage(),
                                          ),
                                        );
                                      }
                                    },
                                    label: Text(
                                      'รายงานปัญหาที่พบ',
                                      style: textTheme.bodySmall!.copyWith(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    icon: const Icon(
                                        Icons.report_problem_rounded),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.groups_rounded),
                                    label: Text(
                                      'เกี่ยวกับผู้พัฒนา และแอปพลิเคชัน',
                                      style: textTheme.bodySmall!.copyWith(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          scrollable: true,
                                          title: Row(
                                            spacing: 16,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Image.asset(
                                                  'assets/images/app_icon.png',
                                                  width: 50,
                                                  height: 50,
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                spacing: 8,
                                                children: [
                                                  Text(
                                                    'เกี่ยวกับแอปพลิเคชัน',
                                                    style: textTheme.bodyMedium!
                                                        .copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'เวอร์ชัน $appVersion',
                                                    style: textTheme.bodySmall!
                                                        .copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              spacing: 16,
                                              children: [
                                                Text(
                                                  'แอปนี้ถูกพัฒนาด้วย Flutter โดย',
                                                  style: textTheme.bodySmall!
                                                      .copyWith(
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
                                                  style: textTheme.bodySmall!
                                                      .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  'เพื่อสร้างแอปพลิเคชันที่สามารถช่วยให้นักเรียนบริหารจัดการตารางเรียนและงานต่าง ๆ ได้อย่างเป็นระบบ ช่วยลดความสับสนในการจัดสรรเวลา พร้อมทั้งเพิ่มความคล่องตัวในการติดตามงานหรือกิจกรรมที่ต้องทำในแต่ละวัน โดยมุ่งเน้นให้การใช้งานเป็นไปอย่างสะดวก เข้าใจง่าย และสามารถตอบสนองต่อความต้องการของผู้เรียนในยุคดิจิทัลที่เทคโนโลยีเข้ามามีบทบาทในชีวิตประจำวันมากยิ่งขึ้น',
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
                                                    builder: (context) =>
                                                        LicensePage(
                                                      applicationName:
                                                          'School Day',
                                                      applicationVersion:
                                                          appVersion,
                                                      applicationIcon:
                                                          ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
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
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  Text(
                                    'เวอร์ชัน $appVersion',
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
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
