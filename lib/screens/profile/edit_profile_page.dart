import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
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

  Future<User?> getCurrentUser() async {
    await FirebaseAuth.instance.currentUser?.reload();
    return FirebaseAuth.instance.currentUser;
  }

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
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
              onPressed: _isChanged ? () {} : null,
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
                                    key: ValueKey(
                                      photoUrl + UniqueKey().toString(),
                                    ),
                                    imageUrl: photoUrl,
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
