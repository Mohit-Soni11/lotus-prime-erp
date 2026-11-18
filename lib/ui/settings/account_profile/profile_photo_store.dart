import 'dart:io';

import '../../../core/storage/app_storage_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePhotoStore {
  static const _keyPrefix = 'lotus_erp_profile_photo_';

  Future<File?> read(String uid) async {
    final preferences = await SharedPreferences.getInstance();
    final path = preferences.getString('$_keyPrefix$uid');
    if (path == null) return null;
    final photo = File(path);
    return await photo.exists() ? photo : null;
  }

  Future<File> save(String uid, File selected) async {
    final base = await AppStoragePaths.supportDirectory();
    final directory = Directory('${base.path}${Platform.pathSeparator}profile');
    await directory.create(recursive: true);
    final target = File(
      '${directory.path}${Platform.pathSeparator}photo_$uid.jpg',
    );
    if (selected.path != target.path) {
      await selected.copy(target.path);
    }
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString('$_keyPrefix$uid', target.path)) {
      throw const FileSystemException('Could not save profile photo path.');
    }
    return target;
  }

  Future<void> remove(String uid) async {
    final preferences = await SharedPreferences.getInstance();
    final path = preferences.getString('$_keyPrefix$uid');
    if (path != null) {
      final photo = File(path);
      if (await photo.exists()) await photo.delete();
    }
    await preferences.remove('$_keyPrefix$uid');
  }
}
