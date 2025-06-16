import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:school_day/components/others/check_latest_profile_image.dart';
import 'package:school_day/screens/navigation_menu.dart';
import 'package:school_day/screens/profile/change_password_page.dart';
import 'package:school_day/services/database/user/user_document.dart';
import 'package:school_day/services/image/image_helper.dart';
import 'package:school_day/styles/styles.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.email,
    required this.username,
  });

  final String email;
  final String username;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late User? user;
  final ImageHelper _imageHelper = ImageHelper();
  late final TextEditingController _usernameController =
      TextEditingController();
  bool _isChanged = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final UserDocument userDocument;

  Future<User?> getCurrentUser() async {
    await FirebaseAuth.instance.currentUser?.reload();
    return FirebaseAuth.instance.currentUser;
  }

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    userDocument = UserDocument(user!.email!);

    _usernameController.value = TextEditingValue(text: widget.username);

    _usernameController.addListener(() {
      final isChanged =
          _usernameController.text.trim() != widget.username.trim();
      if (_isChanged != isChanged) {
        setState(() {
          _isChanged = isChanged;
        });
      }
    });

    updateProfileImageUrl(user!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'แก้ไขข้อมูลโปรไฟล์',
          style: textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _isChanged
                  ? () async {
                      if (formKey.currentState!.validate()) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Center(
                            child: LoadingAnimationWidget.fourRotatingDots(
                              color: primaryColor,
                              size: 80,
                            ),
                          ),
                        );

                        await userDocument
                            .updateUsername(_usernameController.text.trim());

                        if (!context.mounted) return;

                        Navigator.pop(context);

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NavigationMenu(
                              screenIndex: 3,
                            ),
                          ),
                          (route) => false,
                        );
                      }
                    }
                  : null,
              label: const Text('บันทึก'),
              icon: const Icon(
                Icons.save_rounded,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          if (user == null) {
            return Center(
              child: LoadingAnimationWidget.fourRotatingDots(
                color: primaryColor,
                size: 80,
              ),
            );
          }

          final photoUrl = user!.photoURL;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 16,
                    children: [
                      FittedBox(
                        fit: BoxFit.contain,
                        child: ClipOval(
                          child: CircleAvatar(
                            radius: 64,
                            child: photoUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: photoUrl,
                                    placeholder: (context, url) {
                                      return LoadingAnimationWidget.beat(
                                        color: primaryColor,
                                        size: 80,
                                      );
                                    },
                                    errorWidget: (context, url, error) {
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
                      TextButton(
                        onPressed: () async {
                          final picked =
                              await _imageHelper.pickImage(multiple: false);

                          if (picked.isNotEmpty) {
                            final selected = picked.first;

                            if (!context.mounted) return;

                            final cropped = await _imageHelper.crop(
                              file: selected,
                              title: 'ครอบตัดรูปภาพโปรไฟล์',
                              cropStyle: CropStyle.circle,
                              context: context,
                            );

                            if (cropped != null) {
                              if (!context.mounted) return;

                              await uploadProfileAndUpdateAuth(
                                image: XFile(cropped.path),
                                context: context,
                              );
                            }
                          }
                        },
                        child: Text(
                          'เลือกรูปภาพ',
                          style: textTheme.bodySmall,
                        ),
                      ),
                      Form(
                        key: formKey,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 16,
                          children: [
                            const Icon(Icons.person_rounded),
                            Expanded(
                              child: TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  labelText: 'ชื่อผู้ใช้งาน',
                                  hintText: 'ชื่อผู้ใช้งาน',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "โปรดระบุชื่อผู้ใช้งาน";
                                  }

                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(
                                  'ไม่สามารถเปลี่ยนอีเมลได้',
                                  style: textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Text(
                                  'ทางผู้พัฒนายังไม่ได้เพิ่มฟีเจอร์นี้ ขออภัยในความไม่สะดวก',
                                  style: textTheme.bodySmall,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('ปิด'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.email_rounded),
                              const SizedBox(
                                width: 16,
                              ),
                              Text(
                                'อีเมล',
                                style: textTheme.bodySmall!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                widget.email,
                                style: textTheme.bodySmall,
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if (!kDebugMode) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text(
                                    'ไม่สามารถเปลี่ยนรหัสผ่านได้',
                                    style: textTheme.bodyMedium!.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    'ทางผู้พัฒนายังไม่ได้เพิ่มฟีเจอร์นี้ ขออภัยในความไม่สะดวก',
                                    style: textTheme.bodySmall,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('ปิด'),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return const ChangePasswordPage();
                                },
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.password_rounded),
                              const SizedBox(
                                width: 16,
                              ),
                              Text(
                                'รหัสผ่าน',
                                style: textTheme.bodySmall!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
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
        final rawBytes = await image.readAsBytes();

        final compressedBytes = await FlutterImageCompress.compressWithList(
          rawBytes,
          quality: 70,
          format: CompressFormat.jpeg,
        );

        uploadTask = storageRef.putData(
          compressedBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          image.path,
          '${image.path}_compressed.jpg',
          quality: 70,
        );

        if (compressedFile == null) throw 'ไม่สามารถบีบอัดไฟล์รูปภาพได้';

        uploadTask = storageRef.putFile(
          File(compressedFile.path),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      final oldUrl = user!.photoURL;

      if (oldUrl != null) {
        await CachedNetworkImage.evictFromCache(oldUrl);
      }
      await CachedNetworkImage.evictFromCache(url);

      await user!.updatePhotoURL(url);
      await user!.reload();

      final userDocRef =
          FirebaseFirestore.instance.collection('Users').doc(widget.email);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDocRef);

        if (!snapshot.exists) {
          transaction.set(userDocRef, {'profileImageVersion': 1});
        } else {
          final currentVersion = snapshot.get('profileImageVersion') ?? 0;
          transaction.update(userDocRef, {
            'profileImageVersion': currentVersion + 1,
          });
        }
      });

      setState(() {
        user = FirebaseAuth.instance.currentUser;
      });
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการอัปโหลดโปรไฟล์: $e');

      if (context.mounted) {
        final errorMessage = e.toString().contains('Message too long')
            ? 'ไม่สามารถอัปโหลดรูปภาพได้: ไฟล์รูปภาพมีขนาดใหญ่เกินไป'
            : 'เกิดข้อผิดพลาด $e';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}
