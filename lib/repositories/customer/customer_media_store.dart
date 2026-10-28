import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CustomerMediaStore {
  CustomerMediaStore({Directory? root}) : _rootOverride = root;

  final Directory? _rootOverride;

  Future<Directory> _root() async {
    final support = _rootOverride ?? await getApplicationSupportDirectory();
    return Directory('${support.path}${Platform.pathSeparator}customer_media');
  }

  Future<String?> persist(
      String? sourcePath, int customerId, String kind) async {
    if (sourcePath == null || sourcePath.trim().isEmpty) return null;
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const FileSystemException('Customer image is missing');
    }
    if (await _isOwnedByCustomer(source.path, customerId)) {
      return source.path;
    }

    final length = await source.length();
    if (length > 15 * 1024 * 1024) {
      throw const FileSystemException('Customer image exceeds 15 MB');
    }
    final fileName = source.uri.pathSegments.last.toLowerCase();
    final extension = fileName.contains('.') ? fileName.split('.').last : '';
    if (!const {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'}
        .contains(extension)) {
      throw const FileSystemException('Unsupported customer image format');
    }
    final directory = Directory(
      '${(await _root()).path}${Platform.pathSeparator}$customerId',
    );
    await directory.create(recursive: true);
    final destination = File(
      '${directory.path}${Platform.pathSeparator}${kind}_${DateTime.now().microsecondsSinceEpoch}.$extension',
    );
    await source.copy(destination.path);
    return destination.path;
  }

  Future<bool> isOwned(String path) async {
    final root = (await _root()).absolute.path.toLowerCase();
    final candidate = File(path).absolute.path.toLowerCase();
    return candidate.startsWith('$root${Platform.pathSeparator}');
  }

  Future<bool> _isOwnedByCustomer(String path, int customerId) async {
    final directory = Directory(
      '${(await _root()).path}${Platform.pathSeparator}$customerId',
    ).absolute.path.toLowerCase();
    return File(path)
        .absolute
        .path
        .toLowerCase()
        .startsWith('$directory${Platform.pathSeparator}');
  }

  Future<void> deleteIfOwned(String? path) async {
    if (path == null || !await isOwned(path)) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
