import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/google_drive_auth.dart';
import 'package:lotus_erp/features/settings/backup_restore/domain/google_drive_client.dart';
import 'google_drive_backup_test_support.dart';

void main() {
  test('Desktop OAuth uses loopback, PKCE and backup plus OTP scopes',
      () async {
    final secrets = MemoryBackupSecrets();
    String? expectedChallenge;
    var tokenCalls = 0;
    final http = FakeBackupHttp((uri, method, headers, body) async {
      if (uri.path == '/token') {
        tokenCalls++;
        final form = Uri.splitQueryString(utf8.decode(body));
        expect(form['grant_type'], 'authorization_code');
        expect(form['client_id'], 'test.apps.googleusercontent.com');
        expect(form['client_secret'], 'desktop-test-secret');
        expect(GoogleDriveAuth.challenge(form['code_verifier']!),
            expectedChallenge);
        expect(form['code'], 'test-code');
        return backupJsonResponse({
          'access_token': 'access',
          'refresh_token': 'refresh',
          'expires_in': 3600,
          'scope':
              '${GoogleDriveAuth.driveScope} ${GoogleDriveAuth.gmailSendScope} openid email'
        });
      }
      return backupJsonResponse({
        'email': 'owner@example.test',
        'sub': 'account-1',
        'email_verified': true
      });
    });
    final auth = GoogleDriveAuth(
        http: http,
        secrets: secrets,
        applicationClient: const GoogleDriveClient(
            clientId: 'test.apps.googleusercontent.com',
            clientSecret: 'desktop-test-secret'),
        openBrowser: (uri) async {
          expect(uri.host, 'accounts.google.com');
          final query = uri.queryParameters;
          expect(query['scope'], contains(GoogleDriveAuth.driveScope));
          expect(query['scope'], contains(GoogleDriveAuth.gmailSendScope));
          expect(query['code_challenge_method'], 'S256');
          expect(query['access_type'], 'offline');
          expectedChallenge = query['code_challenge'];
          final redirect = Uri.parse(query['redirect_uri']!);
          expect(redirect.host, '127.0.0.1');
          final browser = HttpClient();
          try {
            final rejected = await (await browser.getUrl(redirect.replace(
                    queryParameters: {'state': 'wrong', 'code': 'bad'})))
                .close();
            expect(rejected.statusCode, 400);
            await rejected.drain<void>();
            expect(tokenCalls, 0);
            final accepted = await (await browser.getUrl(redirect.replace(
                    queryParameters: {
                  'state': query['state']!,
                  'code': 'test-code'
                })))
                .close();
            expect(accepted.statusCode, 200);
            await accepted.drain<void>();
          } finally {
            browser.close(force: true);
          }
          return true;
        });
    await auth.load();
    await auth.signIn();
    expect(auth.connected, isTrue);
    expect(auth.canSendRecoveryEmail, isTrue);
    expect(auth.email, 'owner@example.test');
    final identity = await auth.verifiedIdentity();
    expect(identity.email, 'owner@example.test');
    expect(identity.subject, 'account-1');
    expect(await auth.accessToken(), 'access');
    expect(tokenCalls, 1);
    expect(secrets.values['google-tokens'], contains('refresh'));
    final restarted = GoogleDriveAuth(
        http: http,
        secrets: secrets,
        applicationClient: const GoogleDriveClient(clientId: ''));
    await restarted.load();
    expect(restarted.configured, isTrue);
    expect(restarted.connected, isTrue);
    expect(await restarted.accessToken(), 'access');
  });

  test(
      'refresh is shared by concurrent callers and preserves the refresh token',
      () async {
    var refreshed = 0;
    final secrets = MemoryBackupSecrets();
    secrets.values['google-client'] =
        jsonEncode({'client_id': 'test.apps.googleusercontent.com'});
    secrets.values['google-tokens'] = jsonEncode({
      'client_id': 'test.apps.googleusercontent.com',
      'refresh_token': 'original-refresh',
      'access_token': 'expired',
      'expiresAt': DateTime(2000).toIso8601String()
    });
    final http = FakeBackupHttp((uri, method, headers, body) async {
      refreshed++;
      expect(Uri.splitQueryString(utf8.decode(body))['refresh_token'],
          'original-refresh');
      return backupJsonResponse(
          {'access_token': 'new-access', 'expires_in': 3600});
    });
    final auth = GoogleDriveAuth(http: http, secrets: secrets);
    await auth.load();
    expect(await Future.wait([auth.accessToken(), auth.accessToken()]),
        ['new-access', 'new-access']);
    expect(refreshed, 1);
    expect(jsonDecode(secrets.values['google-tokens']!)['refresh_token'],
        'original-refresh');
  });

  test('unconfigured builds do not launch a misleading Google sign-in',
      () async {
    var openedBrowser = false;
    final auth = GoogleDriveAuth(
        http: FakeBackupHttp((a, b, c, d) async => backupJsonResponse({})),
        secrets: MemoryBackupSecrets(),
        applicationClient: const GoogleDriveClient(clientId: ''),
        openBrowser: (_) async {
          openedBrowser = true;
          return true;
        });
    await auth.load();
    await expectLater(
        auth.signIn(),
        throwsA(isA<StateError>().having((error) => error.message, 'message',
            contains('not available in this build'))));
    expect(openedBrowser, isFalse);
  });

  test('unverified Google email cannot be used for account recovery', () async {
    final secrets = MemoryBackupSecrets();
    secrets.values['google-client'] =
        jsonEncode({'client_id': 'test.apps.googleusercontent.com'});
    secrets.values['google-tokens'] = jsonEncode({
      'client_id': 'test.apps.googleusercontent.com',
      'refresh_token': 'refresh',
      'access_token': 'access',
      'expiresAt':
          DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    });
    final auth = GoogleDriveAuth(
      http: FakeBackupHttp(
          (uri, method, headers, body) async => backupJsonResponse({
                'email': 'owner@example.test',
                'sub': 'account-1',
                'email_verified': false,
              })),
      secrets: secrets,
    );
    await auth.load();
    await expectLater(auth.verifiedIdentity(), throwsStateError);
  });

  test('application identity preserves matching tokens across updates',
      () async {
    final http = FakeBackupHttp((a, b, c, d) async => backupJsonResponse({}));
    final existing = await connectedTestGoogle(http);
    final auth = GoogleDriveAuth(
        http: http,
        secrets: existing.secrets,
        applicationClient: const GoogleDriveClient(
            clientId: 'test.apps.googleusercontent.com'));
    await auth.load();
    expect(auth.connected, isTrue);
    expect(await auth.accessToken(), 'test-access');
    expect(auth.email, 'owner@example.test');
  });

  test(
      'application identity takes precedence and never reuses another client token',
      () async {
    final http = FakeBackupHttp((a, b, c, d) async => backupJsonResponse({}));
    final existing = await connectedTestGoogle(http);
    final auth = GoogleDriveAuth(
        http: http,
        secrets: existing.secrets,
        applicationClient: const GoogleDriveClient(
            clientId: 'replacement.apps.googleusercontent.com'));
    await auth.load();
    expect(auth.configured, isTrue);
    expect(auth.connected, isFalse);
    expect(auth.email, isNull);
    expect(await existing.secrets.read('google-tokens'), isNotNull);
    await expectLater(auth.accessToken(), throwsStateError);
  });

  test('missing application identity never erases a saved Google connection',
      () async {
    final http = FakeBackupHttp((a, b, c, d) async => backupJsonResponse({}));
    final existing = await connectedTestGoogle(http);
    await existing.secrets.delete('google-client');
    final originalTokens = await existing.secrets.read('google-tokens');
    final missingIdentity = GoogleDriveAuth(
        http: http,
        secrets: existing.secrets,
        applicationClient: const GoogleDriveClient(clientId: ''));
    await missingIdentity.load();
    expect(missingIdentity.configured, isFalse);
    expect(missingIdentity.connected, isFalse);
    expect(missingIdentity.email, isNull);
    expect(await existing.secrets.read('google-tokens'), originalTokens);

    final restoredIdentity = GoogleDriveAuth(
        http: http,
        secrets: existing.secrets,
        applicationClient: const GoogleDriveClient(
            clientId: 'test.apps.googleusercontent.com'));
    await restoredIdentity.load();
    expect(restoredIdentity.connected, isTrue);
    expect(await restoredIdentity.accessToken(), 'test-access');
  });

  test('a configured build repairs malformed cached application identity',
      () async {
    final http = FakeBackupHttp((a, b, c, d) async => backupJsonResponse({}));
    final existing = await connectedTestGoogle(http);
    await existing.secrets.write('google-client', '{broken');
    final configured = GoogleDriveAuth(
        http: http,
        secrets: existing.secrets,
        applicationClient: const GoogleDriveClient(
            clientId: 'test.apps.googleusercontent.com',
            clientSecret: 'test-desktop-secret'));
    await configured.load();
    final restarted = GoogleDriveAuth(
        http: http,
        secrets: existing.secrets,
        applicationClient: const GoogleDriveClient(clientId: ''));
    await restarted.load();
    expect(restarted.connected, isTrue);
    expect(await restarted.accessToken(), 'test-access');
  });
}
