import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:school_day/services/image/image_helper.dart';

class ProfileImage extends StatefulWidget {
  const ProfileImage({super.key});

  @override
  State<ProfileImage> createState() => _ProfileImageState();
}

class _ProfileImageState extends State<ProfileImage> {
  final ImageHelper _imageHelper = ImageHelper();
  final user = FirebaseAuth.instance.currentUser;
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    photoUrl = user?.photoURL;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: CircleAvatar(
              radius: 64,
              backgroundImage: photoUrl != null
                  ? NetworkImage(Uri.parse(photoUrl!).toString())
                  : const AssetImage('assets/images/blank_profile.jpg'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () async {
            final picked = await _imageHelper.pickImage(multiple: false);

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
          child: const Text('เลือกรูปภาพ'),
        ),
        ElevatedButton(
          onPressed: () async {
            await FirebaseAuth.instance.currentUser?.reload();
            final refreshedUser = FirebaseAuth.instance.currentUser;
            setState(() {
              photoUrl = refreshedUser?.photoURL;
            });
          },
          child: const Text('รีเฟรชรูปโปรไฟล์'),
        )
      ],
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
      builder: (_) => const Center(child: CircularProgressIndicator()),
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

      print('Download URL: $url');

      setState(() {
        photoUrl = user!.photoURL;
      });
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
