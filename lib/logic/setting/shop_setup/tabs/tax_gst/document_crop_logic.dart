// -----------------------------------------------------------------------------
// FILE: document_crop_logic.dart
// TYPE: Core / Utility / Logic
// AUTHOR: Senior System Architect
// DESCRIPTION: Decoupled document cropping logic with strict memory management
//              and isolated error handling (Zero UI dependency in logic layer).
// -----------------------------------------------------------------------------

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart' as native_crop;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DocumentCropLogic {
  final ImagePicker _picker = ImagePicker();
  static const int maxFileSizeMb = 10;

  /// 🚀 UPGRADE: Removed BuildContext. Throws FormatException on error,
  /// allowing the UI layer to catch it and show a Snackbar cleanly.
  Future<File?> pickDocumentFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Optimized quality for fast processing
      );

      if (pickedFile == null) return null;

      File file = File(pickedFile.path);
      int sizeInBytes = await file.length();
      double sizeInMb = sizeInBytes / (1024 * 1024);

      if (sizeInMb > maxFileSizeMb) {
        throw const FormatException("FILE_TOO_LARGE");
      }
      return file;
    } catch (e) {
      debugPrint("Picker Error: $e");
      rethrow; // Passes the error to the UI layer
    }
  }

  Future<File?> cropDocumentMobile(File originalFile, Color brandColor) async {
    try {
      native_crop.CroppedFile? croppedFile =
          await native_crop.ImageCropper().cropImage(
        sourcePath: originalFile.path,
        uiSettings: [
          native_crop.AndroidUiSettings(
            toolbarTitle: 'Secure Document Crop',
            toolbarColor: brandColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: native_crop.CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
          native_crop.IOSUiSettings(
            title: 'Secure Document Crop',
            aspectRatioLockEnabled: false,
            resetAspectRatioEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) return File(croppedFile.path);
      return null;
    } catch (e) {
      debugPrint("Crop Error: $e");
      return null;
    }
  }

  Future<File> saveCroppedBitmap(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = 'doc_crop_${DateTime.now().millisecondsSinceEpoch}.png';
    final tempFile = File(p.join(tempDir.path, fileName));
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  /// 🚀 UPGRADE: Hard memory cleanup to prevent device storage bloat
  Future<void> clearCache(File? image) async {
    if (image != null) {
      // 1. Evict from Flutter RAM Cache
      FileImage(image).evict();

      // 2. Delete physical temporary file from storage
      if (await image.exists()) {
        try {
          await image.delete();
        } catch (e) {
          debugPrint("File Deletion Error: $e");
        }
      }
    }
  }
}
