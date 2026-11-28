import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/google_drive_client.dart';
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

class VerifiedGoogleIdentity {
  const VerifiedGoogleIdentity({required this.email, required this.subject});

  final String email;
  final String subject;
}

class GoogleDriveAuth {
  GoogleDriveAuth(
      {required this.http,
      BackupSecretStore? secrets,
      this.applicationClient = const GoogleDriveClient.fromEnvironment(),
      Future<bool> Function(Uri)? openBrowser})
      : secrets = secrets ?? const SecureBackupSecretStore(),
        openBrowser = openBrowser ??
            ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication));
  final BackupHttpTransport http;
  final BackupSecretStore secrets;
  final GoogleDriveClient applicationClient;
  final Future<bool> Function(Uri) openBrowser;
  static const driveScope = 'https://www.googleapis.com/auth/drive.appdata';
  static const gmailSendScope = 'https://www.googleapis.com/auth/gmail.send';
  static final _tokenUri = Uri.https('oauth2.googleapis.com', '/token');
  GoogleDriveClient? _client;
  Map<String, dynamic>? _tokens;
  Future<String>? _refreshing;
  Completer<void>? _cancel;
  bool get configured => _client != null;
  bool get connected => configured && _tokens?['refresh_token'] is String;
  bool get canSendRecoveryEmail =>
      connected &&
      (_tokens?['scope'] as String? ?? '').split(' ').contains(gmailSendScope);
  String? get email => _tokens?['email'] as String?;
  String? get subject => _tokens?['subject'] as String?;

  Future<void> load() async {
    _client = null;
    _tokens = null;
    final cachedClient = await secrets.read('google-client');
    _client = applicationClient.configured
        ? applicationClient
        : _storedClient(cachedClient);
    if (applicationClient.configured) {
      final encodedClient = jsonEncode({
        'client_id': applicationClient.clientId,
        if (applicationClient.clientSecret.isNotEmpty)
          'client_secret': applicationClient.clientSecret,
      });
      if (cachedClient != encodedClient) {
        await secrets.write('google-client', encodedClient);
      }
    }
    final tokens = await secrets.read('google-tokens');
    if (_client == null || tokens == null) return;
    final savedTokens = Map<String, dynamic>.from(jsonDecode(tokens) as Map);
    if (savedTokens['client_id'] == _client!.clientId) {
      _tokens = savedTokens;
    }
    // A missing or different build identity must not erase a saved connection.
    // Tokens are replaced after successful sign-in or removed by Disconnect.
  }

  GoogleDriveClient? _storedClient(String? stored) {
    if (stored == null) return null;
    final values = jsonDecode(stored) as Map;
    final client = GoogleDriveClient(
        clientId: values['client_id'] as String? ?? '',
        clientSecret: values['client_secret'] as String? ?? '');
    return client.configured ? client : null;
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
      throw StateError(
          'Google account connection is not available in this build of Lotus ERP. Local backup and restore are available.');
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
        'client_id': _client!.clientId,
        'redirect_uri': redirect,
        'response_type': 'code',
        'scope': '$driveScope $gmailSendScope openid email',
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
      final identity =
          await _fetchVerifiedIdentity(tokens['access_token'] as String);
      _tokens = {
        ...tokens,
        'client_id': _client!.clientId,
        'email': identity.email,
        'subject': identity.subject,
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

  Future<VerifiedGoogleIdentity> verifiedIdentity() async {
    final identity = await _fetchVerifiedIdentity(await accessToken());
    _tokens = {
      ..._tokens!,
      'email': identity.email,
      'subject': identity.subject,
    };
    await secrets.write('google-tokens', jsonEncode(_tokens));
    return identity;
  }

  Future<VerifiedGoogleIdentity> _fetchVerifiedIdentity(
      String accessToken) async {
    final user = await http.send(
        Uri.https('openidconnect.googleapis.com', '/v1/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'});
    if (user.status != 200) {
      throw StateError('Could not verify the connected Google account.');
    }
    final identity = await user.json();
    final email = identity['email'];
    final subject = identity['sub'];
    if (email is! String ||
        email.isEmpty ||
        subject is! String ||
        subject.isEmpty ||
        identity['email_verified'] != true) {
      throw StateError('Google account email is not verified.');
    }
    return VerifiedGoogleIdentity(email: email, subject: subject);
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
      'client_id': _client!.clientId,
      if (_client!.clientSecret.isNotEmpty)
        'client_secret': _client!.clientSecret
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
          : 'Google could not connect your account. Please try again. If this continues, contact Lotus ERP support.');
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
