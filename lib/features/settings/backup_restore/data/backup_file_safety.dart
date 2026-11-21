import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

Future<String> backupFileHash(File file) async =>
    (await sha256.bind(file.openRead()).first).toString();

void validateArchivePath(String name) {
  if (name.isEmpty ||
      name.contains('\\') ||
      name.contains(':') ||
      name.contains('\x00') ||
      p.posix.isAbsolute(name) ||
      p.posix.normalize(name) != name ||
      name.split('/').any((segment) =>
          segment.isEmpty ||
          segment == '.' ||
          segment == '..' ||
          segment.endsWith('.') ||
          segment.endsWith(' ') ||
          RegExp(r'^(CON|PRN|AUX|NUL|COM[1-9¹²³]|LPT[1-9¹²³])(?:\.|$)',
                  caseSensitive: false)
              .hasMatch(segment))) {
    throw const FormatException('The backup contains an unsafe file path.');
  }
}

Future<void> requireNoLinks(String path) async {
  var current = p.normalize(p.absolute(path));
  while (true) {
    if (await FileSystemEntity.type(current, followLinks: false) ==
        FileSystemEntityType.link) {
      throw StateError('Linked folders cannot be used for backup or restore.');
    }
    final parent = p.dirname(current);
    if (parent == current) break;
    current = parent;
  }
}

Future<void> copyBackupTree(String source, String destination) async {
  await requireNoLinks(source);
  final type = await FileSystemEntity.type(source, followLinks: false);
  if (type == FileSystemEntityType.file) {
    await File(destination).parent.create(recursive: true);
    await File(source).copy(destination);
    if (await backupFileHash(File(source)) !=
        await backupFileHash(File(destination))) {
      throw StateError(
          'A file changed while the backup was being created. Retry the backup.');
    }
    return;
  }
  await Directory(destination).create(recursive: true);
  if (type == FileSystemEntityType.notFound) return;
  if (type != FileSystemEntityType.directory) {
    throw StateError('Unsupported backup source.');
  }
  await for (final child in Directory(source).list(followLinks: false)) {
    if (child is Link) {
      throw StateError('Linked files cannot be included in the backup.');
    }
    await copyBackupTree(
        child.path, p.join(destination, p.basename(child.path)));
  }
}

Future<void> deleteBackupEntity(String path) async {
  await requireNoLinks(path);
  final type = await FileSystemEntity.type(path, followLinks: false);
  if (type == FileSystemEntityType.directory) {
    await Directory(path).delete(recursive: true);
  } else if (type == FileSystemEntityType.file) {
    await File(path).delete();
  } else if (type != FileSystemEntityType.notFound) {
    throw StateError('Unexpected file type in the recovery workspace.');
  }
}

Future<void> renameBackupEntity(String source, String destination) async {
  await requireNoLinks(source);
  await requireNoLinks(destination);
  final type = await FileSystemEntity.type(source, followLinks: false);
  if (type == FileSystemEntityType.directory) {
    await Directory(source).rename(destination);
  } else if (type == FileSystemEntityType.file) {
    await File(source).rename(destination);
  } else {
    throw StateError('The recovery source is missing.');
  }
}
