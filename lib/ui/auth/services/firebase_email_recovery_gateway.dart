import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'email_recovery_gateway.dart';

/// Uses Firebase only to prove ownership of an email address. Local passwords
/// and sessions never leave this installation.
class FirebaseEmailRecoveryGateway implements EmailRecoveryGateway {
  FirebaseEmailRecoveryGateway({
    required this.apiKey,
    required this.continueUrl,
    HttpClient? client,
  }) : _client = client ?? HttpClient();

  final String apiKey;
  final Uri continueUrl;
  final HttpClient _client;

  @override
  bool get isConfigured => apiKey.isNotEmpty && continueUrl.isScheme('https');

  @override
  Future<void> sendSignInLink(String email) async {
    if (!isConfigured) {
      throw const EmailRecoveryException('Email recovery is not configured.');
    }
    await _post('sendOobCode', {
      'requestType': 'EMAIL_SIGNIN',
      'email': email,
      'continueUrl': continueUrl.toString(),
      'canHandleCodeInApp': true,
    });
  }

  @override
  Future<VerifiedEmailIdentity> verifySignInLink(
      String email, String link) async {
    if (!isConfigured) {
      throw const EmailRecoveryException('Email recovery is not configured.');
    }
    final code = _extractCode(link);
    if (code == null) {
      throw const EmailRecoveryException(
          'Paste the complete email sign-in link.');
    }
    final response = await _post('signInWithEmailLink', {
      'email': email,
      'oobCode': code,
    });
    final verifiedEmail = response['email'] as String?;
    final uid = response['localId'] as String?;
    if (verifiedEmail == null || uid == null || uid.isEmpty) {
      throw const EmailRecoveryException('Email link could not be verified.');
    }
    return VerifiedEmailIdentity(email: verifiedEmail.toLowerCase(), uid: uid);
  }

  static String? _extractCode(String link) {
    final uri = Uri.tryParse(link.trim());
    if (uri == null || !uri.isScheme('https')) return null;
    String? find(Uri value, int depth) {
      if (value.queryParameters['mode'] == 'signIn') {
        final code = value.queryParameters['oobCode'];
        if (code != null && code.isNotEmpty) return code;
      }
      if (depth == 0) return null;
      for (final key in ['link', 'deep_link_id', 'continueUrl']) {
        final nested = value.queryParameters[key];
        if (nested == null) continue;
        final nestedUri = Uri.tryParse(nested);
        if (nestedUri != null && nestedUri.isScheme('https')) {
          final result = find(nestedUri, depth - 1);
          if (result != null) return result;
        }
      }
      return null;
    }

    return find(uri, 3);
  }

  Future<Map<String, dynamic>> _post(
      String action, Map<String, Object?> payload) async {
    try {
      final uri = Uri.https('identitytoolkit.googleapis.com',
          '/v1/accounts:$action', {'key': apiKey});
      final request =
          await _client.postUrl(uri).timeout(const Duration(seconds: 12));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));
      final response =
          await request.close().timeout(const Duration(seconds: 20));
      final body = await utf8.decoder.bind(response).join();
      final parsed = jsonDecode(body) as Map<String, dynamic>;
      if (response.statusCode != HttpStatus.ok) {
        final code = (parsed['error'] as Map?)?['message'] as String? ?? '';
        if (code.contains('EXPIRED_OOB_CODE') ||
            code.contains('INVALID_OOB_CODE')) {
          throw const EmailRecoveryException(
              'This link has expired or was already used. Request a new one.');
        }
        if (code.contains('TOO_MANY_ATTEMPTS') ||
            code.contains('QUOTA_EXCEEDED')) {
          throw const EmailRecoveryException(
              'Email limit reached. Try again later or use your recovery code.');
        }
        throw const EmailRecoveryException(
            'Email service could not complete the request. Try again later.');
      }
      return parsed;
    } on EmailRecoveryException {
      rethrow;
    } on SocketException {
      throw const EmailRecoveryException(
          'Internet connection is required for email recovery.');
    } on TimeoutException {
      throw const EmailRecoveryException(
          'Email service timed out. Please retry.');
    } on FormatException {
      throw const EmailRecoveryException(
          'Invalid response from email service.');
    } on HttpException {
      throw const EmailRecoveryException(
          'Email service could not complete the request. Try again later.');
    } on HandshakeException {
      throw const EmailRecoveryException(
          'Secure connection to email service failed.');
    }
  }
}
