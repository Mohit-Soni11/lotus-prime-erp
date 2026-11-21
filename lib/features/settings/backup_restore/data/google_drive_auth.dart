import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'backup_http_transport.dart';

abstract interface class BackupSecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureBackupSecretStore implements BackupSecretStore {
  const SecureBackupSecretStore();
  static const _storage = FlutterSecureStorage();
  String _key(String key) =>
      'lotus_erp.${kReleaseMode ? 'production' : 'development'}.backup.$key';
  @override
  Future<String?> read(String key) => _storage.read(key: _key(key));
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: _key(key), value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: _key(key));
}

class GoogleDriveAuth {
  GoogleDriveAuth(
      {required this.http,
      BackupSecretStore? secrets,
      Future<bool> Function(Uri)? openBrowser})
      : secrets = secrets ?? const SecureBackupSecretStore(),
        openBrowser = openBrowser ??
            ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication));
  final BackupHttpTransport http;
  final BackupSecretStore secrets;
  final Future<bool> Function(Uri) openBrowser;
  static const driveScope = 'https://www.googleapis.com/auth/drive.appdata';
  static final _tokenUri = Uri.https('oauth2.googleapis.com', '/token');
  Map<String, dynamic>? _client;
  Map<String, dynamic>? _tokens;
  Future<String>? _refreshing;
  Completer<void>? _cancel;
  bool get configured => _client != null;
  bool get connected => configured && _tokens?['refresh_token'] is String;
  String? get email => _tokens?['email'] as String?;

  Future<void> load() async {
    final client = await secrets.read('google-client');
    final tokens = await secrets.read('google-tokens');
    _client = client == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(client) as Map);
    _tokens = tokens == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(tokens) as Map);
    if (_tokens != null &&
        (_client == null || _tokens!['client_id'] != _client!['client_id'])) {
      _tokens = null;
      await secrets.delete('google-tokens');
    }
  }

  Future<void> configure(String contents) async {
    final document = jsonDecode(contents);
    if (document is! Map || document['installed'] is! Map) {
      throw const FormatException(
          'Select the Google OAuth JSON for a Desktop app. Web and service-account credentials are not supported.');
    }
    final installed = document['installed'] as Map;
    final id = installed['client_id'];
    if (id is! String || !id.endsWith('.apps.googleusercontent.com')) {
      throw const FormatException('The Google Desktop client ID is invalid.');
    }
    final client = {
      'client_id': id,
      if (installed['client_secret'] is String)
        'client_secret': installed['client_secret']
    };
    await secrets.write('google-client', jsonEncode(client));
    await secrets.delete('google-tokens');
    _client = client;
    _tokens = null;
  }

  static String _random(int length) {
    final random = Random.secure();
    return base64UrlEncode(
            List<int>.generate(length, (_) => random.nextInt(256)))
        .replaceAll('=', '');
  }

  static String challenge(String verifier) =>
      base64UrlEncode(sha256.convert(utf8.encode(verifier)).bytes)
          .replaceAll('=', '');

  Future<void> signIn() async {
    if (_client == null) {
      throw StateError('Configure the Google Desktop client first.');
    }
    if (_cancel != null) {
      throw StateError('Google sign-in is already in progress.');
    }
    final verifier = _random(48);
    final state = _random(32);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirect = 'http://127.0.0.1:${server.port}/oauth2/callback';
    final code = Completer<String>();
    final cancellation = Completer<void>();
    _cancel = cancellation;
    final subscription = server.listen((request) async {
      if (request.uri.path != '/oauth2/callback' || request.method != 'GET') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      final query = request.uri.queryParameters;
      final validState = query['state'] == state;
      request.response.headers.contentType = ContentType.html;
      request.response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      request.response.headers.set('X-Content-Type-Options', 'nosniff');
      request.response.headers.set('Referrer-Policy', 'no-referrer');
      request.response.statusCode =
          validState ? HttpStatus.ok : HttpStatus.badRequest;
      request.response.write(
          '<!doctype html><html><head><title>Lotus ERP</title></head>'
          '<body style="font-family:system-ui;padding:48px"><h1>Lotus ERP</h1>'
          '<p>${validState ? 'Return to Lotus ERP to finish connecting your backup account.' : 'This sign-in response was rejected. Return to Lotus ERP and try again.'}</p></body></html>');
      await request.response.close();
      if (code.isCompleted || !validState) return;
      if (query['error'] != null || query['code'] == null) {
        code.completeError(
            StateError('Google sign-in was cancelled or not approved.'));
      } else {
        code.complete(query['code']!);
      }
    });
    try {
      final authorize = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': _client!['client_id'] as String,
        'redirect_uri': redirect,
        'response_type': 'code',
        'scope': '$driveScope openid email',
        'state': state,
        'code_challenge': challenge(verifier),
        'code_challenge_method': 'S256',
        'access_type': 'offline',
        'prompt': 'consent select_account',
      });
      final waiting = Future.any<String>([
        code.future,
        cancellation.future
            .then((_) => throw StateError('Google sign-in was cancelled.')),
      ]);
      final responses = await Future.wait<String>([
        openBrowser(authorize).then((opened) {
          if (!opened) {
            throw StateError('Could not open your browser for Google sign-in.');
          }
          return '';
        }),
        waiting,
      ], eagerError: true)
          .timeout(const Duration(minutes: 3),
              onTimeout: () => throw StateError(
                  'Google sign-in timed out. Try connecting again.'));
      final authorizationCode = responses[1];
      final tokens = await _tokenRequest({
        'grant_type': 'authorization_code',
        'code': authorizationCode,
        'code_verifier': verifier,
        'redirect_uri': redirect
      });
      if (tokens['refresh_token'] is! String ||
          !(tokens['scope'] as String? ?? '').split(' ').contains(driveScope)) {
        throw StateError(
            'Google Drive backup access was not granted. Connect again and approve the backup permission.');
      }
      final user = await http.send(
          Uri.https('openidconnect.googleapis.com', '/v1/userinfo'),
          headers: {'Authorization': 'Bearer ${tokens['access_token']}'});
      if (user.status != 200) {
        throw StateError('Could not verify the connected Google account.');
      }
      final identity = await user.json();
      if (identity['email'] is! String || identity['sub'] is! String) {
        throw StateError('Google did not return the account identity.');
      }
      _tokens = {
        ...tokens,
        'client_id': _client!['client_id'],
        'email': identity['email'],
        'subject': identity['sub'],
        'expiresAt': DateTime.now()
            .add(Duration(seconds: (tokens['expires_in'] as num).toInt()))
            .toIso8601String()
      };
      await secrets.write('google-tokens', jsonEncode(_tokens));
    } finally {
      _cancel = null;
      await subscription.cancel();
      await server.close(force: true);
    }
  }

  void cancelSignIn() {
    if (_cancel != null && !_cancel!.isCompleted) _cancel!.complete();
  }

  Future<String> accessToken() async {
    if (!connected) {
      throw StateError(
          'Connect your Google account before using Drive backups.');
    }
    final expires = DateTime.tryParse(_tokens!['expiresAt'] as String? ?? '');
    if (expires != null &&
        expires.isAfter(DateTime.now().add(const Duration(minutes: 2)))) {
      return _tokens!['access_token'] as String;
    }
    final pending = _refreshing ??= _refresh();
    try {
      return await pending;
    } finally {
      if (identical(_refreshing, pending)) _refreshing = null;
    }
  }

  Future<String> _refresh() async {
    final response = await _tokenRequest({
      'grant_type': 'refresh_token',
      'refresh_token': _tokens!['refresh_token'] as String
    });
    _tokens = {
      ..._tokens!,
      'access_token': response['access_token'],
      'expiresAt': DateTime.now()
          .add(Duration(seconds: (response['expires_in'] as num).toInt()))
          .toIso8601String()
    };
    await secrets.write('google-tokens', jsonEncode(_tokens));
    return response['access_token'] as String;
  }

  Future<Map<String, dynamic>> _tokenRequest(Map<String, String> values) async {
    final fields = {
      ...values,
      'client_id': _client!['client_id'] as String,
      if (_client!['client_secret'] != null)
        'client_secret': _client!['client_secret'] as String
    };
    final bytes = utf8.encode(Uri(queryParameters: fields).query);
    final response = await http.send(_tokenUri,
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: Stream.value(bytes),
        contentLength: bytes.length);
    final result = await response.json();
    if (response.status != 200 || result['access_token'] is! String) {
      throw StateError(result['error'] == 'invalid_grant'
          ? 'Google authorization expired. Reconnect your Google account.'
          : 'Google sign-in failed. Check the Desktop OAuth configuration and try again.');
    }
    return result;
  }

  Future<void> disconnect() async {
    final refresh = _tokens?['refresh_token'] as String?;
    await secrets.delete('google-tokens');
    _tokens = null;
    if (refresh != null) {
      try {
        final bytes =
            utf8.encode(Uri(queryParameters: {'token': refresh}).query);
        final result = await http.send(
            Uri.https('oauth2.googleapis.com', '/revoke'),
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: Stream.value(bytes),
            contentLength: bytes.length);
        await result.body.drain<void>();
      } on Exception {/* Local credentials are already removed when offline. */}
    }
  }
}
