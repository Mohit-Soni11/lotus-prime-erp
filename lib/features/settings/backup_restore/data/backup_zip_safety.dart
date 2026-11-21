import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'backup_file_safety.dart';

/// Rejects unsafe metadata before decoding and bounds every decompressed file.
abstract final class BackupZipSafety {
  static Future<void> preflight(File file,
      {required int maxFiles, required int maxBytes}) async {
    final handle = await file.open();
    try {
      final size = await handle.length();
      final start = size > 65557 ? size - 65557 : 0;
      await handle.setPosition(start);
      final tail = await handle.read(size - start);
      final data = ByteData.sublistView(tail);
      var end = -1;
      for (var i = tail.length - 22; i >= 0; i--) {
        if (data.getUint32(i, Endian.little) == 0x06054b50 &&
            i + 22 + data.getUint16(i + 20, Endian.little) == tail.length) {
          end = i;
          break;
        }
      }
      if (end < 0 ||
          data.getUint16(end + 4, Endian.little) != 0 ||
          data.getUint16(end + 6, Endian.little) != 0) {
        throw const FormatException('Invalid or multi-volume backup archive.');
      }
      var count = data.getUint16(end + 10, Endian.little);
      var bytes = data.getUint32(end + 12, Endian.little);
      var offset = data.getUint32(end + 16, Endian.little);
      if (count == 0xffff || bytes == 0xffffffff || offset == 0xffffffff) {
        if (start + end < 20) {
          throw const FormatException('Invalid ZIP64 archive.');
        }
        await handle.setPosition(start + end - 20);
        final locator = ByteData.sublistView(await handle.read(20));
        if (locator.getUint32(0, Endian.little) != 0x07064b50 ||
            locator.getUint32(16, Endian.little) != 1) {
          throw const FormatException('Invalid ZIP64 locator.');
        }
        await handle.setPosition(locator.getUint64(8, Endian.little));
        final directory = ByteData.sublistView(await handle.read(56));
        if (directory.lengthInBytes != 56 ||
            directory.getUint32(0, Endian.little) != 0x06064b50) {
          throw const FormatException('Invalid ZIP64 directory.');
        }
        count = directory.getUint64(32, Endian.little);
        bytes = directory.getUint64(40, Endian.little);
        offset = directory.getUint64(48, Endian.little);
      }
      if (count > maxFiles + 1000 ||
          bytes > 64 * 1024 * 1024 ||
          offset < 0 ||
          offset + bytes > size ||
          size > maxBytes) {
        throw const FormatException(
            'The archive exceeds safe processing limits.');
      }
    } finally {
      await handle.close();
    }
  }

  static void validateDirectory(InputFileStream input,
      {required int maxFiles, required int maxBytes}) {
    final directory = ZipDirectory()..read(input);
    final names = <String>{};
    var total = 0;
    if (directory.fileHeaders.length > maxFiles + 1000) {
      throw const FormatException('Too many archive entries.');
    }
    for (final file in directory.fileHeaders) {
      final name = file.filename.endsWith('/')
          ? file.filename.substring(0, file.filename.length - 1)
          : file.filename;
      validateArchivePath(name);
      total += file.uncompressedSize;
      if (!names.add(name.toLowerCase()) ||
          ((file.externalFileAttributes >> 16) & 0xf000) == 0xa000 ||
          (file.generalPurposeBitFlag & 1) != 0 ||
          !const {0, 8}.contains(file.compressionMethod) ||
          total > maxBytes) {
        throw const FormatException(
            'Duplicate, linked, encrypted or oversized archive content.');
      }
    }
    input.setPosition(0);
  }

  static Future<void> extract(ArchiveFile entry, File target, int limit) async {
    await target.parent.create(recursive: true);
    final file = OutputFileStream(target.path);
    try {
      entry.writeContent(_BoundedBackupOutput(file, limit));
    } finally {
      await file.close();
    }
    if (await target.length() != entry.size) {
      throw const FormatException('Backup entry size does not match.');
    }
  }
}

class _BoundedBackupOutput extends OutputStream {
  _BoundedBackupOutput(this.output, this.limit)
      : super(byteOrder: ByteOrder.littleEndian);
  final OutputFileStream output;
  final int limit;
  void _check(int count) {
    if (count < 0 || length + count > limit) {
      throw const FormatException(
          'Backup decompression exceeded its declared size.');
    }
  }

  @override
  int get length => output.length;
  @override
  void writeByte(int value) {
    _check(1);
    output.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _check(length ?? bytes.length);
    output.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    while (!stream.isEOS) {
      writeBytes(stream
          .readBytes(stream.length > 65536 ? 65536 : stream.length)
          .toUint8List());
    }
  }

  @override
  void flush() => output.flush();
  @override
  void clear() {
    output.clear();
  }

  @override
  Uint8List subset(int start, [int? end]) => output.subset(start, end);
}
