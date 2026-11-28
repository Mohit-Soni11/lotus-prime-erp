import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_erp/features/settings/backup_restore/data/google_drive_auth.dart';
import 'package:lotus_erp/ui/auth/services/google_otp_email_gateway.dart';
import 'package:lotus_erp/ui/auth/services/otp_email_gateway.dart';

import 'google_drive_backup_test_support.dart';

void main() {
  test('OTP email uses the verified connected account and Gmail send',
      () async {
    final secrets = MemoryBackupSecrets();
    secrets.values['google-client'] =
        jsonEncode({'client_id': 'test.apps.googleusercontent.com'});
    secrets.values['google-tokens'] = jsonEncode({
      'client_id': 'test.apps.googleusercontent.com',
      'refresh_token': 'refresh',
      'access_token': 'access',
      'expiresAt':
          DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
      'scope':
          '${GoogleDriveAuth.driveScope} ${GoogleDriveAuth.gmailSendScope} openid email',
    });
    var sends = 0;
    final http = FakeBackupHttp((uri, method, headers, body) async {
      if (uri.host == 'openidconnect.googleapis.com') {
        return backupJsonResponse({
          'email': 'owner@example.com',
          'sub': 'google-owner',
          'email_verified': true,
        });
      }
      expect(uri.host, 'gmail.googleapis.com');
      expect(uri.path, '/gmail/v1/users/me/messages/send');
      expect(method, 'POST');
      expect(headers['Authorization'], 'Bearer access');
      final raw = (jsonDecode(utf8.decode(body)) as Map)['raw'] as String;
      final message = utf8.decode(base64Url.decode(base64Url.normalize(raw)));
      expect(message, contains('To: owner@example.com'));
      expect(message, contains('123456'));
      sends++;
      return backupJsonResponse({'id': 'sent'});
    });
    final gateway = GoogleOtpEmailGateway(
        http: http, auth: GoogleDriveAuth(http: http, secrets: secrets));
    await gateway.send(
        email: 'owner@example.com',
        googleSubject: 'google-owner',
        code: '123456');
    expect(sends, 1);
    await expectLater(
      gateway.send(
          email: 'owner@example.com',
          googleSubject: 'different-account',
          code: '123456'),
      throwsA(isA<OtpEmailException>()),
    );
    expect(sends, 1);
  });

  test('Gmail API rejection gives an actionable error', () async {
    final secrets = MemoryBackupSecrets();
    secrets.values['google-client'] =
        jsonEncode({'client_id': 'test.apps.googleusercontent.com'});
    secrets.values['google-tokens'] = jsonEncode({
      'client_id': 'test.apps.googleusercontent.com',
      'refresh_token': 'refresh',
      'access_token': 'access',
      'expiresAt':
          DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
      'scope':
          '${GoogleDriveAuth.driveScope} ${GoogleDriveAuth.gmailSendScope} openid email',
    });
    final http = FakeBackupHttp((uri, method, headers, body) async {
      if (uri.host == 'openidconnect.googleapis.com') {
        return backupJsonResponse({
          'email': 'owner@example.com',
          'sub': 'google-owner',
          'email_verified': true,
        });
      }
      return backupJsonResponse({
        'error': {
          'code': 403,
          'errors': [
            {'reason': 'accessNotConfigured'}
          ],
        }
      }, status: 403);
    });
    final gateway = GoogleOtpEmailGateway(
        http: http, auth: GoogleDriveAuth(http: http, secrets: secrets));
    await expectLater(
      gateway.send(
          email: 'owner@example.com',
          googleSubject: 'google-owner',
          code: '123456'),
      throwsA(isA<OtpEmailException>().having((error) => error.message,
          'message', contains('Gmail API is disabled'))),
    );
  });
}
