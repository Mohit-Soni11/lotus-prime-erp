import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Keeps installed application data outside the replaceable program directory.
/// Development continues to use its existing locations and cannot seed V1.
final class AppStoragePaths {
  AppStoragePaths._();

  static const productionFolder = 'Lotus ERP';

  static Future<Directory> _productionDirectory() async {
    final localAppData = Platform.isWindows
        ? Platform.environment['LOCALAPPDATA']?.trim()
        : null;
    final basePath = localAppData != null && localAppData.isNotEmpty
        ? localAppData
        : (await getApplicationSupportDirectory()).path;
    final directory = Directory(p.join(basePath, productionFolder, 'Data'));
    await directory.create(recursive: true);
    return directory;
  }

  static Future<Directory> documentsDirectory() => kReleaseMode
      ? _productionDirectory()
      : getApplicationDocumentsDirectory();

  static Future<Directory> supportDirectory() =>
      kReleaseMode ? _productionDirectory() : getApplicationSupportDirectory();

  static Future<Directory> shopDatabaseDirectory() async {
    if (kReleaseMode) return _productionDirectory();
    final support = await getApplicationSupportDirectory();
    final directory =
        Directory(p.join(support.path, productionFolder, 'Development'));
    await directory.create(recursive: true);
    return directory;
  }
}
