import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:school_day/services/image/image_helper.dart';

class ProfileImage extends StatefulWidget {
  const ProfileImage({super.key});

  @override
  State<ProfileImage> createState() => _ProfileImageState();
}

class _ProfileImageState extends State<ProfileImage> {
  File? _imageFile;
  Uint8List? _webImageBytes;
  final ImageHelper _imageHelper = ImageHelper();

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;

    if (kIsWeb && _webImageBytes != null) {
      imageProvider = MemoryImage(_webImageBytes!);
    } else if (!kIsWeb && _imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else {
      imageProvider = const AssetImage('assets/images/blank_profile.jpg');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: CircleAvatar(
              radius: 64,
              backgroundImage: imageProvider,
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
                if (kIsWeb) {
                  final bytes = await cropped.readAsBytes();
                  setState(() {
                    _webImageBytes = bytes;
                  });
                } else {
                  setState(() {
                    _imageFile = File(cropped.path);
                  });
                }
              }
            }
          },
          child: const Text('เลือกรูปภาพ'),
        ),
      ],
    );
  }
}
