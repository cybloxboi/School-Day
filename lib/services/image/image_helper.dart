import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:school_day/styles/styles.dart';

class ImageHelper {
  final ImagePicker _imagePicker;
  final ImageCropper _imageCropper;

  ImageHelper({
    ImagePicker? imagePicker,
    ImageCropper? imageCropper,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        _imageCropper = imageCropper ?? ImageCropper();

  Future<List<XFile>> pickImage({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 100,
    bool multiple = false,
  }) async {
    if (kIsWeb) {
      if (multiple) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
        );

        if (result != null) {
          return result.files
              .map((file) => XFile(file.bytes != null
                  ? Uri.dataFromBytes(file.bytes!).toString()
                  : file.path!))
              .toList();
        }

        return [];
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          return [
            XFile(file.bytes != null
                ? Uri.dataFromBytes(file.bytes!).toString()
                : file.path!)
          ];
        }

        return [];
      }
    } else {
      if (multiple) {
        return await _imagePicker.pickMultiImage(imageQuality: imageQuality);
      }

      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: imageQuality,
      );

      if (file != null) return [file];
      return [];
    }
  }

  Future<CroppedFile?> crop({
    required XFile file,
    required String title,
    required BuildContext context,
    CropStyle cropStyle = CropStyle.rectangle,
  }) async {
    return await _imageCropper.cropImage(
      sourcePath: file.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: secondaryColor,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
          initAspectRatio: CropAspectRatioPreset.square,
          hideBottomControls: true,
          cropStyle: cropStyle,
        ),
        WebUiSettings(
          context: context,
          viewwMode: WebViewMode.mode_2,
          size: CropperSize(
            width: (MediaQuery.of(context).size.width * 0.5).floor(),
            height: (MediaQuery.of(context).size.height * 0.5).floor(),
          ),
          translations: WebTranslations(
            title: title,
            rotateLeftTooltip: 'หมุนซ้าย',
            rotateRightTooltip: 'หมุนขวา',
            cancelButton: 'ยกเลิก',
            cropButton: 'ตกลง',
          ),
        ),
      ],
    );
  }
}
