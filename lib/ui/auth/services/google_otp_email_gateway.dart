import 'dart:convert';

import '../../../features/settings/backup_restore/data/backup_http_transport.dart';
import '../../../features/settings/backup_restore/data/google_drive_auth.dart';
import 'otp_email_gateway.dart';

/// Sends only to the verified mailbox already linked to the local owner.
class GoogleOtpEmailGateway implements OtpEmailGateway {
  factory GoogleOtpEmailGateway(
      {GoogleDriveAuth? auth, BackupHttpTransport? http}) {
    final transport = http ?? IoBackupHttpTransport();
    return GoogleOtpEmailGateway._(
        auth ??
            GoogleDriveAuth(
                http: transport,
                localDevelopmentConfigPath: 'config/google-drive.local.json'),
        transport);
  }

  GoogleOtpEmailGateway._(this._auth, this._http);

  final GoogleDriveAuth _auth;
  final BackupHttpTransport _http;

  @override
  Future<void> send({
    required String email,
    required String googleSubject,
    required String code,
  }) async {
    await _auth.load();
    if (!_auth.configured) {
      throw const OtpEmailException(
          'Google account connection is unavailable in this build. Use your saved recovery code or start Lotus ERP with Google integration enabled.');
    }
    if (!_auth.canSendRecoveryEmail) {
      throw const OtpEmailException(
        'Reconnect your Google account in Backup & Restore to allow recovery emails.',
      );
    }
    final identity = await _auth.verifiedIdentity();
    if (identity.subject != googleSubject ||
        identity.email.toLowerCase() != email) {
      throw const OtpEmailException(
        'The connected Google account does not match the recovery email.',
      );
    }
    final message = [
      'From: Lotus ERP <${identity.email}>',
      'To: ${identity.email}',
      'Subject: Lotus ERP password reset code',
      'MIME-Version: 1.0',
      'Content-Type: text/plain; charset=UTF-8',
      '',
      'Your Lotus ERP password reset code is $code.',
      'It expires in 10 minutes. If you did not request this, ignore this email.',
    ].join('\r\n');
    final raw = base64UrlEncode(utf8.encode(message)).replaceAll('=', '');
    final payload = utf8.encode(jsonEncode({'raw': raw}));
    final response = await _http.send(
      Uri.https('gmail.googleapis.com', '/gmail/v1/users/me/messages/send'),
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ${await _auth.accessToken()}',
        'Content-Type': 'application/json',
      },
      body: Stream.value(payload),
      contentLength: payload.length,
    );
    if (response.status != 200) {
      Map<String, dynamic> error = const {};
      try {
        error = await response.json();
      } catch (_) {
        // Keep the status-based message when Google returns a non-JSON error.
      }
      throw _deliveryError(response.status, error);
    }
    final sent = await response.json();
    if (sent['id'] is! String || (sent['id'] as String).isEmpty) {
      throw const OtpEmailException(
        'Google did not confirm the email. Try again shortly.',
      );
    }
  }

  static OtpEmailException _deliveryError(
      int status, Map<String, dynamic> response) {
    final error = response['error'];
    final details = error is Map ? error['errors'] : null;
    final first = details is List && details.isNotEmpty ? details.first : null;
    final reason = first is Map ? first['reason']?.toString() : null;
    final metadata = error is Map ? error['details'] : null;
    final serviceDisabled = metadata is List &&
        metadata
            .any((item) => item is Map && item['reason'] == 'SERVICE_DISABLED');
    if (serviceDisabled || reason == 'accessNotConfigured') {
      return const OtpEmailException(
          'Gmail API is disabled for this Google project. Enable it, then try again.');
    }
    if (status == 401 || reason == 'insufficientPermissions') {
      return const OtpEmailException(
          'Google permission expired. Reconnect the account in Backup & Restore.');
    }
    if (status == 429 ||
        reason == 'rateLimitExceeded' ||
        reason == 'userRateLimitExceeded' ||
        reason == 'dailyLimitExceeded') {
      return const OtpEmailException(
          'Gmail sending limit reached. Try again later or use your recovery code.');
    }
    if (reason == 'domainPolicy') {
      return const OtpEmailException(
          'Your Google Workspace policy does not allow this app to send email.');
    }
    return OtpEmailException(
        'Google rejected the email request (HTTP $status). Check Gmail API access.');
  }
}
