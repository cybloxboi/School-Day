import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:school_day/services/database/user/user_document.dart';
import 'package:school_day/services/image/image_helper.dart';
import 'package:school_day/styles/styles.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImageHelper _imageHelper = ImageHelper();
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () {},
              label: const Text('แก้ไขข้อมูล'),
              icon: const Icon(Icons.edit_rounded),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                child: Column(
                  spacing: 16,
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
                                            return LoadingAnimationWidget.beat(
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
                          ],
                        );
                      },
                    ),
                    // TextButton(
                    //   onPressed: () async {
                    //     final picked =
                    //         await _imageHelper.pickImage(multiple: false);

                    //     if (picked.isNotEmpty) {
                    //       final selected = picked.first;

                    //       if (!context.mounted) return;

                    //       final cropped = await _imageHelper.crop(
                    //         file: selected,
                    //         title: 'ครอบตัดรูปภาพโปรไฟล์',
                    //         cropStyle: CropStyle.circle,
                    //         context: context,
                    //       );

                    //       if (cropped != null) {
                    //         if (!context.mounted) return;

                    //         await uploadProfileAndUpdateAuth(
                    //           image: XFile(cropped.path),
                    //           context: context,
                    //         );
                    //       }
                    //     }
                    //   },
                    //   child: Text(
                    //     'เลือกรูปภาพ',
                    //     style: textTheme.bodySmall,
                    //   ),
                    // ),
                  ],
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

  Future<void> uploadProfileAndUpdateAuth({
    required XFile image,
    required BuildContext context,
  }) async {
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: LoadingAnimationWidget.fourRotatingDots(
          color: primaryColor,
          size: 80,
        ),
      ),
    );

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user!.uid}.jpg');

      UploadTask uploadTask;

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        uploadTask = storageRef.putData(bytes);
      } else {
        uploadTask = storageRef.putFile(File(image.path));
      }

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      await user!.updatePhotoURL(url);
      await user!.reload();

      setState(() {});
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการอัปโหลดโปรไฟล์: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}
