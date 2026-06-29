// -----------------------------------------------------------------------------
// FILE: photo_logic.dart
// TYPE: Service / Logic Layer
// AUTHOR: Senior System Architect
// DESCRIPTION: 🚀 UPGRADED: Added kIsWeb cross-platform safety.
//              High-performance image handling, optimized memory eviction,
//              and storage leak prevention without UI coupling.
// -----------------------------------------------------------------------------

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart' as native_crop;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../../../core/logging/app_logger.dart';
import 'package:flutter/foundation.dart';

class PhotoUploadLogic {
  final ImagePicker _picker = ImagePicker();

  // 🚀 UPGRADE: Globally synchronized with BasicInfoLogic
  static const int maxFileSizeMb = 5;

  /// **1. Image Picking & Secure Validation**
  /// Throws an exception with a user-friendly message if validation fails.
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Optimized for ERP performance
      );

      if (pickedFile == null) return null;

      // 🚀 UPGRADE: Use XFile's length() which is safe for Web & Native
      // Using File(pickedFile.path).length() directly can cause Web issues.
      int sizeInBytes = await pickedFile.length();
      double sizeInMb = sizeInBytes / (1024 * 1024);

      if (sizeInMb > maxFileSizeMb) {
        throw Exception("File too large. Maximum size is ${maxFileSizeMb}MB.");
      }

      // 🛡️ Security: Validate Extension to prevent malicious files
      // 🚀 UPGRADE: Bypassed file path extension check for Web as it uses blob URLs
      if (!kIsWeb) {
        String ext = p.extension(pickedFile.path).toLowerCase();
        if (ext != '.jpg' && ext != '.jpeg' && ext != '.png') {
          throw Exception(
              "Invalid format. Only JPG and PNG images are allowed.");
        }
      }

      return File(pickedFile.path);
    } catch (e) {
      AppLogger.error("Picker Error: $e");
      rethrow; // Let the UI layer catch this and show the feedback overlay
    }
  }

  /// **2. Mobile Native Cropping**
  Future<File?> cropImageMobile(File originalFile, Color toolbarColor) async {
    // 🚀 UPGRADE: Web does not support this native cropper UI
    if (kIsWeb) return originalFile;

    try {
      native_crop.CroppedFile? croppedFile =
          await native_crop.ImageCropper().cropImage(
        sourcePath: originalFile.path,
        uiSettings: [
          native_crop.AndroidUiSettings(
            toolbarTitle: 'Adjust Identity Photo',
            toolbarColor: toolbarColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: native_crop.CropAspectRatioPreset.square,
            lockAspectRatio: false,
          ),
          native_crop.IOSUiSettings(
            title: 'Adjust Identity Photo',
            minimumAspectRatio: 1.0,
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      AppLogger.error("Mobile Crop Error: $e");
      throw Exception("Failed to crop image.");
    }
  }

  /// **3. Desktop Cropping Helper: Secure Temp Save**
  Future<File> saveCroppedBitmap(Uint8List bytes) async {
    // 🚀 UPGRADE: Web doesn't support Temp Directories like Native
    if (kIsWeb) {
      throw Exception(
          "Web byte saving should be handled via memory, not File System.");
    }

    try {
      final tempDir = await getTemporaryDirectory();
      // Unique naming convention for easy cleanup
      final fileName =
          'erp_img_crop_${DateTime.now().millisecondsSinceEpoch}.png';
      final tempFile = File(p.join(tempDir.path, fileName));
      await tempFile.writeAsBytes(bytes);
      return tempFile;
    } catch (e) {
      AppLogger.error("Bitmap Save Error: $e");
      throw Exception("Failed to process cropped image.");
    }
  }

  /// **4. Memory Management: Clear RAM Cache**
  void clearImageCache(File? image) {
    // 🚀 UPGRADE: FileImage().evict() crashes on Web. Bypassed for Web.
    if (image != null && !kIsWeb) {
      try {
        FileImage(image).evict();
      } catch (e) {
        AppLogger.error("Cache Eviction Error: $e");
      }
    }
  }

  /// **5. 🚀 UPGRADE: Storage Management (Fixes Storage Leaks)**
  /// Deletes old temporary crop files from the device.
  Future<void> clearOldTempFiles() async {
    // 🚀 UPGRADE: Web file system bypass
    if (kIsWeb) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final List<FileSystemEntity> files = tempDir.listSync();
      for (var file in files) {
        if (file is File && file.path.contains('erp_img_crop_')) {
          await file.delete();
        }
      }
    } catch (e) {
      AppLogger.error("Temp Cleanup Error: $e");
    }
  }
}
