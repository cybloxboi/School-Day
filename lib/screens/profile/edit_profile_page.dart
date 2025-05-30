import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:school_day/components/auth/validate.dart';
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
  late final User? user;
  final ImageHelper _imageHelper = ImageHelper();

  late final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _usernameController =
      TextEditingController();

  Future<User?> getCurrentUser() async {
    await user?.reload();
    return user;
  }

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _emailController.value = TextEditingValue(text: widget.email);
    _usernameController.value = TextEditingValue(text: widget.username);
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
      ),
      backgroundColor: backgroundColor,
      body: SafeArea(
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
                          const Divider(),
                          Form(
                            child: Column(
                              spacing: 16,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 16,
                                  children: [
                                    const Icon(Icons.email_rounded),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _emailController,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: 'อีเมล',
                                        ),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "โปรดระบุอีเมล";
                                          } else if (!isValidEmail(value)) {
                                            return "อีเมลไม่ถูกต้องน้า";
                                          }

                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 16,
                                  children: [
                                    const Icon(Icons.person_rounded),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _usernameController,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: 'ชื่อผู้ใช้งาน',
                                        ),
                                        keyboardType:
                                            TextInputType.emailAddress,
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
                              ],
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
