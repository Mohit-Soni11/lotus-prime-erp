import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CapturedPhotoStorage {
  CapturedPhotoStorage._();

  static Future<String> persistJpeg({
    required String sourcePath,
    required String module,
    required String fileStem,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('Captured photo file was not found.');
    }

    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(
      p.join(root.path, 'Lotus ERP', 'media', module),
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final safeStem = _safeFileStem(fileStem);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final target = File(p.join(directory.path, '${safeStem}_$timestamp.jpg'));
    await source.copy(target.path);
    return target.path;
  }

  static String _safeFileStem(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return normalized.isEmpty ? 'captured_photo' : normalized;
  }
}
