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
import '../../../../../core/logging/app_logger.dart';
import 'package:flutter/foundation.dart';

class DocumentCropLogic {
  final ImagePicker _picker = ImagePicker();
  static const int maxFileSizeMb = 10;

  /// 🚀 UPGRADE: Removed BuildContext. Throws FormatException on error,
  /// allowing the UI layer to catch it and show a feedback overlay cleanly.
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
      AppLogger.error("Picker Error: $e");
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

      if (croppedFile != null) {
        return persistDocumentFile(File(croppedFile.path));
      }
      return null;
    } catch (e) {
      AppLogger.error("Crop Error: $e");
      return null;
    }
  }

  Future<File> saveCroppedBitmap(
    Uint8List bytes, {
    String filePrefix = 'doc_crop',
  }) async {
    final storageDir = await _managedStorageDir();
    final storedFile = File(
      p.join(storageDir.path, _uniqueFileName(filePrefix, '.png')),
    );
    await storedFile.writeAsBytes(bytes, flush: true);
    return storedFile;
  }

  Future<File> persistDocumentFile(
    File source, {
    String filePrefix = 'doc_upload',
  }) async {
    final storageDir = await _managedStorageDir();
    final storedFile = File(
      p.join(
        storageDir.path,
        _uniqueFileName(filePrefix, _safeExtension(source.path)),
      ),
    );
    return source.copy(storedFile.path);
  }

  /// 🚀 UPGRADE: Hard memory cleanup to prevent device storage bloat
  Future<void> clearCache(File? image) async {
    if (image != null) {
      // 1. Evict from Flutter RAM Cache
      FileImage(image).evict();

      // 2. Delete only files owned by this module's managed storage.
      if (await image.exists() && await _isManagedFile(image)) {
        try {
          await image.delete();
        } catch (e) {
          AppLogger.error("File Deletion Error: $e");
        }
      }
    }
  }

  Future<Directory> _managedStorageDir() async {
    final supportDir = await getApplicationSupportDirectory();
    final storageDir = Directory(p.join(supportDir.path, 'shop_documents'));
    await storageDir.create(recursive: true);
    return storageDir;
  }

  Future<bool> _isManagedFile(File file) async {
    final storageDir = await _managedStorageDir();
    final directory = p.normalize(storageDir.path);
    final filePath = p.normalize(file.path);
    return p.equals(p.dirname(filePath), directory) ||
        p.isWithin(directory, filePath);
  }

  String _safeExtension(String sourcePath) {
    final extension = p.extension(sourcePath).toLowerCase();
    return switch (extension) {
      '.jpg' || '.jpeg' || '.png' || '.webp' => extension,
      _ => '.png',
    };
  }

  String _uniqueFileName(String prefix, String extension) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}$extension';
  }
}
