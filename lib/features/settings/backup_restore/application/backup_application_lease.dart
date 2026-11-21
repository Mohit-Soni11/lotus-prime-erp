import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../data/backup_locations.dart';

class BackupStartupException implements Exception {
  const BackupStartupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Prevents another current-version process from writing during restore.
class BackupApplicationLease {
  RandomAccessFile? _handle;
  Future<void> acquire(BackupLocations locations,
      {bool waitForPrevious = false}) async {
    await locations.root.create(recursive: true);
    final file = await File(p.join(locations.root.path, 'application.lock'))
        .open(mode: FileMode.append);
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while (true) {
      try {
        await file.lock(FileLock.exclusive);
        _handle = file;
        return;
      } on FileSystemException {
        if (!waitForPrevious || DateTime.now().isAfter(deadline)) {
          await file.close();
          throw const BackupStartupException(
              'Lotus ERP is already open. Close the other window before starting this copy.');
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  Future<void> release() async {
    await _handle?.unlock();
    await _handle?.close();
    _handle = null;
  }
}
