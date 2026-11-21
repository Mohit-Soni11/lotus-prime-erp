import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../domain/backup_record.dart';
import 'backup_archive_service.dart';
import 'backup_file_safety.dart';
import 'backup_http_transport.dart';
import 'google_drive_auth.dart';

class GoogleDriveBackupService {
  GoogleDriveBackupService({required this.auth, required this.http});
  final GoogleDriveAuth auth;
  final BackupHttpTransport http;
  static const _fields = 'id,name,size,createdTime,md5Checksum,appProperties';

  Future<List<BackupRecord>> list() async {
    final records = <BackupRecord>[];
    String? page;
    do {
      final response =
          await _send(Uri.https('www.googleapis.com', '/drive/v3/files', {
        'spaces': 'appDataFolder',
        'q':
            "trashed = false and appProperties has { key='lotusProduct' and value='lotus-erp' }",
        'fields': 'nextPageToken,files($_fields)',
        'pageSize': '100',
        'orderBy': 'createdTime desc',
        if (page != null) 'pageToken': page,
      }));
      await _require(response, {200});
      final data = await response.json();
      for (final value in data['files'] as List? ?? const []) {
        final file = Map<String, dynamic>.from(value as Map);
        final properties =
            Map<String, dynamic>.from(file['appProperties'] as Map? ?? {});
        if (properties['lotusBackupId'] is! String ||
            properties['sha256'] is! String) {
          continue;
        }
        records.add(BackupRecord(
            id: properties['lotusBackupId'] as String,
            name: file['name'] as String,
            createdAt: DateTime.parse(file['createdTime'] as String),
            size: int.parse(file['size'] as String? ?? '0'),
            sha256: properties['sha256'] as String,
            missingMediaCount: int.tryParse(
                    properties['missingMediaCount'] as String? ?? '') ??
                0,
            driveId: file['id'] as String));
      }
      page = data['nextPageToken'] as String?;
    } while (page != null);
    return records;
  }

  Future<String> upload(BackupRecord record,
      {void Function(double)? onProgress}) async {
    final source = File(record.localPath!);
    if (!await source.exists() ||
        await source.length() != record.size ||
        await backupFileHash(source) != record.sha256) {
      throw StateError(
          'The local backup changed. Create a fresh backup before uploading.');
    }
    final existing = (await list())
        .where((item) => item.id == record.id && item.sha256 == record.sha256);
    if (existing.isNotEmpty) return existing.first.driveId!;
    final metadata = utf8.encode(jsonEncode({
      'name': record.name,
      'parents': ['appDataFolder'],
      'appProperties': {
        'lotusProduct': 'lotus-erp',
        'lotusBackupId': record.id,
        'sha256': record.sha256,
        'formatVersion': '1',
        'missingMediaCount': '${record.missingMediaCount}',
      }
    }));
    final start = await _send(
        Uri.https('www.googleapis.com', '/upload/drive/v3/files',
            {'uploadType': 'resumable', 'fields': _fields}),
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'X-Upload-Content-Type': 'application/octet-stream',
          'X-Upload-Content-Length': '${record.size}'
        },
        body: Stream.value(metadata),
        length: metadata.length);
    await _require(start, {200, 201});
    final location = Uri.tryParse(start.headers['location'] ?? '');
    await start.body.drain<void>();
    if (location == null ||
        location.scheme != 'https' ||
        !(location.host == 'www.googleapis.com' ||
            location.host == 'content.googleapis.com')) {
      throw StateError('Google Drive returned an invalid upload destination.');
    }
    var offset = 0;
    var retries = 0;
    const chunkSize = 4 * 1024 * 1024;
    while (offset < record.size) {
      final end = (offset + chunkSize).clamp(0, record.size);
      BackupHttpResponse response;
      try {
        response = await _send(location,
            method: 'PUT',
            headers: {
              'Content-Type': 'application/octet-stream',
              'Content-Range': 'bytes $offset-${end - 1}/${record.size}'
            },
            body: source.openRead(offset, end),
            length: end - offset);
      } on Exception {
        if (++retries > 3) rethrow;
        await Future<void>.delayed(Duration(seconds: retries * 2));
        response = await _send(location,
            method: 'PUT',
            headers: {'Content-Range': 'bytes */${record.size}'},
            length: 0);
      }
      if (response.status == 308) {
        final range = RegExp(r'^bytes=0-(\d+)$')
            .firstMatch(response.headers['range'] ?? '');
        final next = range == null ? 0 : int.parse(range.group(1)!) + 1;
        await response.body.drain<void>();
        if (next < 0 ||
            next > record.size ||
            (next <= offset && ++retries > 3)) {
          throw StateError(
              'Google Drive could not resume the backup upload. Retry the upload.');
        }
        if (next > offset) retries = 0;
        offset = next;
        onProgress?.call(offset / record.size);
        continue;
      }
      await _require(response, {200, 201});
      final result = await response.json();
      final checksum = (await md5.bind(source.openRead()).first).toString();
      if (result['id'] is! String ||
          result['md5Checksum'] != checksum ||
          int.tryParse(result['size'] as String? ?? '') != record.size) {
        throw StateError(
            'Google Drive could not verify the uploaded backup. The local backup is still available.');
      }
      onProgress?.call(1);
      return result['id'] as String;
    }
    throw StateError(
        'Google Drive did not confirm the completed upload. Retry the upload.');
  }

  Future<File> download(BackupRecord record, Directory cache,
      {void Function(double)? onProgress}) async {
    final id = record.driveId;
    if (id == null ||
        !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id) ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(record.sha256) ||
        record.size <= 0 ||
        record.size > BackupArchiveService.maxBytes) {
      throw const FormatException('Invalid Google Drive backup details.');
    }
    await requireNoLinks(cache.path);
    await cache.create(recursive: true);
    final target = File(p.join(cache.path, '${const Uuid().v4()}.lotusbackup'));
    final pending = File('${target.path}.pending');
    try {
      final response = await _send(Uri.https(
          'www.googleapis.com', '/drive/v3/files/$id', {'alt': 'media'}));
      await _require(response, {200});
      final output = pending.openWrite();
      var received = 0;
      try {
        await for (final chunk in response.body) {
          received += chunk.length;
          if (received > record.size) {
            throw const FormatException(
                'The downloaded backup is larger than expected.');
          }
          output.add(chunk);
          onProgress?.call(received / record.size);
        }
        await output.flush();
      } finally {
        await output.close();
      }
      if (received != record.size ||
          await backupFileHash(pending) != record.sha256) {
        throw const FormatException(
            'Google Drive backup verification failed. Download the backup again.');
      }
      await pending.rename(target.path);
      return target;
    } finally {
      if (await pending.exists()) await pending.delete();
    }
  }

  Future<BackupHttpResponse> _send(Uri uri,
          {String method = 'GET',
          Map<String, String> headers = const {},
          Stream<List<int>>? body,
          int? length}) async =>
      http.send(uri,
          method: method,
          headers: {
            ...headers,
            'Authorization': 'Bearer ${await auth.accessToken()}'
          },
          body: body,
          contentLength: length);

  Future<void> _require(BackupHttpResponse response, Set<int> allowed) async {
    if (allowed.contains(response.status)) return;
    await response.body.drain<void>();
    throw StateError(switch (response.status) {
      401 => 'Google authorization expired. Reconnect your Google account.',
      403 =>
        'Google Drive denied the request. Check backup permission and available Drive storage.',
      404 => 'The Google Drive backup is no longer available.',
      429 => 'Google Drive is busy. Retry the backup shortly.',
      _ =>
        'Google Drive could not complete the request. Your local backup remains available.',
    });
  }
}
