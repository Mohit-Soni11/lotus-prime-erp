import 'dart:convert';
import 'package:lotus_erp/features/settings/backup_restore/data/backup_http_transport.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/google_drive_auth.dart';

class MemoryBackupSecrets implements BackupSecretStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

class FakeBackupHttp implements BackupHttpTransport {
  FakeBackupHttp(this.handler);
  final Future<BackupHttpResponse> Function(
          Uri uri, String method, Map<String, String> headers, List<int> body)
      handler;
  @override
  Future<BackupHttpResponse> send(Uri uri,
      {String method = 'GET',
      Map<String, String> headers = const {},
      Stream<List<int>>? body,
      int? contentLength}) async {
    final bytes =
        body == null ? <int>[] : await body.expand((chunk) => chunk).toList();
    if (contentLength != null && bytes.length != contentLength) {
      throw StateError('Incorrect HTTP content length');
    }
    return handler(uri, method, headers, bytes);
  }
}

BackupHttpResponse backupJsonResponse(Map<String, dynamic> value,
        {int status = 200, Map<String, String> headers = const {}}) =>
    BackupHttpResponse(
        status, headers, Stream.value(utf8.encode(jsonEncode(value))));

Future<GoogleDriveAuth> connectedTestGoogle(FakeBackupHttp http) async {
  final secrets = MemoryBackupSecrets();
  secrets.values['google-client'] =
      jsonEncode({'client_id': 'test.apps.googleusercontent.com'});
  secrets.values['google-tokens'] = jsonEncode({
    'client_id': 'test.apps.googleusercontent.com',
    'refresh_token': 'test-refresh',
    'access_token': 'test-access',
    'email': 'owner@example.test',
    'expiresAt': DateTime.now().add(const Duration(hours: 1)).toIso8601String()
  });
  final auth = GoogleDriveAuth(http: http, secrets: secrets);
  await auth.load();
  return auth;
}
