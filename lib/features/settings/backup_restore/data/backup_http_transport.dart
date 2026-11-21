import 'dart:convert';
import 'dart:io';

class BackupHttpResponse {
  const BackupHttpResponse(this.status, this.headers, this.body);
  final int status;
  final Map<String, String> headers;
  final Stream<List<int>> body;
  Future<Map<String, dynamic>> json() async {
    final bytes = <int>[];
    await for (final chunk in body) {
      bytes.addAll(chunk);
      if (bytes.length > 2 * 1024 * 1024) {
        throw StateError('Unexpected Google API response size.');
      }
    }
    if (bytes.isEmpty) return {};
    return Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);
  }
}

abstract interface class BackupHttpTransport {
  Future<BackupHttpResponse> send(Uri uri,
      {String method = 'GET',
      Map<String, String> headers = const {},
      Stream<List<int>>? body,
      int? contentLength});
}

class IoBackupHttpTransport implements BackupHttpTransport {
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30);
  @override
  Future<BackupHttpResponse> send(Uri uri,
      {String method = 'GET',
      Map<String, String> headers = const {},
      Stream<List<int>>? body,
      int? contentLength}) async {
    if (uri.scheme != 'https') {
      throw StateError('Google API requests must use HTTPS.');
    }
    final request = await _client.openUrl(method, uri);
    request.followRedirects = false;
    headers.forEach((key, value) => request.headers.set(key, value));
    if (contentLength != null) request.contentLength = contentLength;
    if (body != null) {
      await request.addStream(body).timeout(const Duration(minutes: 3));
    }
    final response = await request.close().timeout(const Duration(minutes: 3));
    return BackupHttpResponse(
        response.statusCode,
        {
          for (final name in [
            HttpHeaders.locationHeader,
            HttpHeaders.rangeHeader,
            HttpHeaders.contentLengthHeader
          ])
            if (response.headers.value(name) != null)
              name: response.headers.value(name)!
        },
        response.timeout(const Duration(minutes: 3)));
  }
}
