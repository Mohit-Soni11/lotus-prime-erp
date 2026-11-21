import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_file_safety.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_http_transport.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/google_drive_backup_service.dart';
import 'package:lotus_erp/features/settings/backup_restore/domain/backup_record.dart';
import 'google_drive_backup_test_support.dart';

void main() {
  test('large Drive upload streams chunks and validates the server checksum',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('lotus-drive-upload-');
    addTearDown(() => directory.delete(recursive: true));
    final bytes = List<int>.generate(4 * 1024 * 1024 + 19, (i) => i % 255);
    final source =
        await File('${directory.path}/sample.lotusbackup').writeAsBytes(bytes);
    final record = BackupRecord(
        id: 'sample-id',
        name: 'sample.lotusbackup',
        createdAt: DateTime.now(),
        size: bytes.length,
        sha256: await backupFileHash(source),
        localPath: source.path);
    var puts = 0;
    final received = <int>[];
    final http = FakeBackupHttp((uri, method, headers, body) async {
      expect(headers['Authorization'], 'Bearer test-access');
      if (method == 'GET') {
        expect(uri.queryParameters['spaces'], 'appDataFolder');
        return backupJsonResponse({'files': []});
      }
      if (method == 'POST') {
        expect(uri.queryParameters['uploadType'], 'resumable');
        return backupJsonResponse({},
            headers: {'location': 'https://www.googleapis.com/upload/session'});
      }
      puts++;
      received.addAll(body);
      if (puts == 1) {
        return const BackupHttpResponse(
            308, {'range': 'bytes=0-4194303'}, Stream.empty());
      }
      return backupJsonResponse({
        'id': 'cloud-file',
        'size': '${bytes.length}',
        'md5Checksum': md5.convert(bytes).toString()
      });
    });
    final drive = GoogleDriveBackupService(
        auth: await connectedTestGoogle(http), http: http);
    expect(await drive.upload(record), 'cloud-file');
    expect(puts, 2);
    expect(received, bytes);
    expect(await source.exists(), isTrue);
  });

  test('download verifies bytes before publishing a usable backup file',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('lotus-drive-download-');
    addTearDown(() => directory.delete(recursive: true));
    final data = [1, 2, 3, 4];
    final http = FakeBackupHttp((uri, method, headers, body) async =>
        BackupHttpResponse(200, {}, Stream.value(data)));
    final drive = GoogleDriveBackupService(
        auth: await connectedTestGoogle(http), http: http);
    final record = BackupRecord(
        id: 'id',
        name: 'backup.lotusbackup',
        createdAt: DateTime.now(),
        size: 4,
        sha256: sha256.convert(data).toString(),
        driveId: 'cloud-file');
    final downloaded = await drive.download(record, directory);
    expect(await downloaded.readAsBytes(), data);
  });

  test('corrupt cloud download leaves no completed or pending file', () async {
    final directory =
        await Directory.systemTemp.createTemp('lotus-drive-corrupt-');
    addTearDown(() => directory.delete(recursive: true));
    final http = FakeBackupHttp((uri, method, headers, body) async =>
        const BackupHttpResponse(200, {}, Stream<List<int>>.empty()));
    final drive = GoogleDriveBackupService(
        auth: await connectedTestGoogle(http), http: http);
    final record = BackupRecord(
        id: 'id',
        name: 'backup.lotusbackup',
        createdAt: DateTime.now(),
        size: 4,
        sha256: sha256.convert([1, 2, 3, 4]).toString(),
        driveId: 'cloud-file');
    await expectLater(drive.download(record, directory), throwsFormatException);
    expect(await directory.list().toList(), isEmpty);
  });
}
