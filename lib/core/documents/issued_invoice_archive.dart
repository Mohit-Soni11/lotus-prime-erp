import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum IssuedInvoiceKind { sales, booking, returnVoucher }

/// Keeps the PDF issued at finalization, separate from mutable bill data.
class IssuedInvoiceArchive {
  const IssuedInvoiceArchive({this.directoryProvider});

  final Future<Directory> Function()? directoryProvider;

  Future<Uint8List?> read(
    IssuedInvoiceKind kind,
    int recordId,
    String documentNumber,
  ) async {
    final file = await _file(kind, recordId, documentNumber);
    final revisions = await _revisionFiles(file);
    final issuedFile = revisions.isNotEmpty ? revisions.last : file;
    if (!await issuedFile.exists()) return null;
    final bytes = await issuedFile.readAsBytes();
    validatePdf(bytes);
    return bytes;
  }

  Future<void> saveRevision(
    IssuedInvoiceKind kind,
    int recordId,
    String documentNumber,
    Uint8List bytes,
  ) async {
    validatePdf(bytes);
    final original = await _file(kind, recordId, documentNumber);
    final directory = _revisionDirectory(original);
    await directory.create(recursive: true);
    var revision = DateTime.now().microsecondsSinceEpoch;
    File issuedFile;
    do {
      issuedFile = File(p.join(directory.path, '$revision.pdf'));
      revision++;
    } while (await issuedFile.exists());

    final pending = File('${issuedFile.path}.tmp');
    try {
      await pending.writeAsBytes(bytes, flush: true);
      await pending.rename(issuedFile.path);
    } finally {
      if (await pending.exists()) await pending.delete();
    }
  }

  Future<Map<String, dynamic>?> readMetadata(
    IssuedInvoiceKind kind,
    int recordId,
    String documentNumber,
  ) async {
    final file = await _metadataFile(kind, recordId, documentNumber);
    if (!await file.exists()) return null;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid issued invoice metadata.');
    }
    return decoded;
  }

  Future<void> saveMetadata(
    IssuedInvoiceKind kind,
    int recordId,
    String documentNumber,
    Map<String, dynamic> metadata,
  ) async {
    final file = await _metadataFile(kind, recordId, documentNumber);
    await file.parent.create(recursive: true);
    final pending = File(
      '${file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      await pending.writeAsString(jsonEncode(metadata), flush: true);
      await pending.rename(file.path);
    } finally {
      if (await pending.exists()) await pending.delete();
    }
  }

  Future<void> saveIfAbsent(
    IssuedInvoiceKind kind,
    int recordId,
    String documentNumber,
    Uint8List bytes,
  ) async {
    validatePdf(bytes);
    final file = await _file(kind, recordId, documentNumber);
    if (await file.exists()) {
      validatePdf(await file.readAsBytes());
      return;
    }

    await file.parent.create(recursive: true);
    final pending =
        File('${file.path}.${DateTime.now().microsecondsSinceEpoch}.tmp');
    try {
      await pending.writeAsBytes(bytes, flush: true);
      if (!await file.exists()) {
        await pending.rename(file.path);
      }
    } finally {
      if (await pending.exists()) await pending.delete();
    }
  }

  Future<File> _file(
    IssuedInvoiceKind kind,
    int recordId,
    String documentNumber,
  ) async {
    if (recordId <= 0) {
      throw ArgumentError.value(recordId, 'recordId', 'Must be positive.');
    }
    final normalizedNumber = documentNumber.trim();
    if (normalizedNumber.isEmpty) {
      throw ArgumentError.value(documentNumber, 'documentNumber', 'Required.');
    }
    final encodedNumber =
        base64UrlEncode(utf8.encode(normalizedNumber)).replaceAll('=', '');
    final support =
        await (directoryProvider?.call() ?? getApplicationSupportDirectory());
    return File(p.join(
      support.path,
      'lotus_erp',
      'issued_invoices',
      kind.name,
      '${recordId}_$encodedNumber.pdf',
    ));
  }

  Directory _revisionDirectory(File original) => Directory(p.join(
        original.parent.path,
        'revisions',
        p.basenameWithoutExtension(original.path),
      ));

  Future<File> _metadataFile(
    IssuedInvoiceKind kind,
    int recordId,
    String documentNumber,
  ) async {
    final original = await _file(kind, recordId, documentNumber);
    return File(p.setExtension(original.path, '.json'));
  }

  Future<List<File>> _revisionFiles(File original) async {
    final directory = _revisionDirectory(original);
    if (!await directory.exists()) return const [];
    final files = await directory
        .list(followLinks: false)
        .where((entry) => entry is File && p.extension(entry.path) == '.pdf')
        .cast<File>()
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  static void validatePdf(Uint8List bytes) {
    const signature = [0x25, 0x50, 0x44, 0x46, 0x2D];
    if (bytes.length < signature.length) {
      throw const FormatException('The issued document is not a PDF.');
    }
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] == signature[i]) continue;
      throw const FormatException('The issued document is not a PDF.');
    }
  }
}
