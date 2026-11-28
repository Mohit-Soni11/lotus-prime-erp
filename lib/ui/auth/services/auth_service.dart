import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import 'auth_result.dart';
import 'auth_session_gateway.dart';
import 'email_recovery_gateway.dart';
import 'firebase_email_recovery_gateway.dart';
import 'local_account_repository.dart';
import 'local_password_hasher.dart';
import 'password_policy.dart';
import 'local_session_store.dart';
import 'google_otp_email_gateway.dart';
import 'otp_email_gateway.dart';
import 'password_recovery_actions.dart';

class AuthService implements AuthSessionGateway, PasswordRecoveryActions {
  AuthService._(
      this._accounts, this._hasher, this._sessions, this._email, this._otpEmail,
      [DateTime Function()? clock])
      : _clock = clock ?? DateTime.now;

  static final AuthService _instance = AuthService._(
      LocalAccountRepository(),
      LocalPasswordHasher(),
      const SecureLocalSessionStore(),
      FirebaseEmailRecoveryGateway(
        apiKey: const String.fromEnvironment('LOTUS_RECOVERY_API_KEY'),
        continueUrl: Uri.parse(
            const String.fromEnvironment('LOTUS_RECOVERY_CONTINUE_URL')),
      ),
      GoogleOtpEmailGateway());
  factory AuthService() => _instance;

  AuthService.forTesting(LocalAccountRepository accounts,
      {required LocalSessionStore sessionStore,
      EmailRecoveryGateway? emailGateway,
      OtpEmailGateway? otpEmailGateway,
      DateTime Function()? clock})
      : this._(accounts, LocalPasswordHasher(), sessionStore, emailGateway,
            otpEmailGateway, clock);

  final LocalAccountRepository _accounts;
  final LocalPasswordHasher _hasher;
  final LocalSessionStore _sessions;
  final EmailRecoveryGateway? _email;
  final OtpEmailGateway? _otpEmail;
  final DateTime Function() _clock;
  final _changes = StreamController<String?>.broadcast();
  String? _signedInUid;
  DateTime? _lastEmailSentAt;
  DateTime? _lastOtpSentAt;
  _OtpChallenge? _otpChallenge;
  bool _otpSending = false;

  bool get isEmailRecoveryAvailable => _email?.isConfigured ?? false;

  Future<String?> getRecoveryEmail() async {
    final record = await _accounts.read();
    if (record?['uid'] != _signedInUid) return null;
    return record?['recovery_email'] as String?;
  }

  Future<bool> isRecoveryLinkedToGoogle({String? subject}) async {
    final record = await _accounts.read();
    return record?['uid'] == _signedInUid &&
        record?['recovery_google_subject'] is String &&
        (subject == null || record?['recovery_google_subject'] == subject);
  }

  Future<AuthResult> verifyRecoverySetupPassword(String currentPassword) async {
    final record = await _accounts.read();
    if (record == null || record['uid'] != _signedInUid) {
      return const AuthResult(AuthResultCode.failure, 'Sign in again.');
    }
    final result = await _checkCurrentPassword(record, currentPassword);
    return result ??
        const AuthResult(AuthResultCode.success, 'Password verified.');
  }

  @override
  String? get currentUserId => _signedInUid;

  @override
  Stream<String?> authUserIds() async* {
    final storedId = await _sessions.readUserId();
    if (storedId != null) {
      final account = await _accounts.read();
      if (account?['uid'] == storedId) {
        _signedInUid = storedId;
      } else {
        await _sessions.clear();
      }
    }
    yield _signedInUid;
    yield* _changes.stream;
  }

  Future<bool> hasOwnerAccount() async => await _accounts.read() != null;

  @override
  Future<SessionCheck> validateCurrentSession() async {
    final record = await _accounts.read();
    return _signedInUid != null && record?['uid'] == _signedInUid
        ? const SessionCheck(SessionCheckStatus.authorized, '')
        : const SessionCheck(SessionCheckStatus.rejected, 'Sign in again.');
  }

  @override
  Future<AuthResult> loginUser(
      {required String username, required String password}) async {
    try {
      final record = await _accounts.read();
      final now = DateTime.now().toUtc();
      final lockedUntil =
          DateTime.tryParse(record?['locked_until'] as String? ?? '');
      if (lockedUntil != null && lockedUntil.isAfter(now)) {
        return const AuthResult(AuthResultCode.failure,
            'Too many attempts. Try again in a few minutes.');
      }
      final valid = record != null &&
          (record['username'] as String).toLowerCase() ==
              username.trim().toLowerCase() &&
          await _hasher.verify(password, record['password_salt'] as List<int>,
              record['password_hash'] as List<int>);
      if (!valid) {
        if (record != null) await _recordFailedAttempt(record, now);
        return const AuthResult(
            AuthResultCode.failure, 'Username or password is incorrect.');
      }
      await _accounts.update({'failed_attempts': 0, 'locked_until': null});
      await _sessions.writeUserId(record['uid'] as String);
      _signedInUid = record['uid'] as String;
      _changes.add(_signedInUid);
      return const AuthResult(AuthResultCode.success, 'Signed in.');
    } catch (_) {
      return const AuthResult(AuthResultCode.failure,
          'Local account could not be opened. Please retry.');
    }
  }

  Future<void> _recordFailedAttempt(
      Map<String, Object?> record, DateTime now) async {
    final attempts = (record['failed_attempts'] as int? ?? 0) + 1;
    await _accounts.update({
      'failed_attempts': attempts >= 5 ? 0 : attempts,
      'locked_until': attempts >= 5
          ? now.add(const Duration(minutes: 5)).toIso8601String()
          : null,
    });
  }

  @override
  Future<AuthResult> registerOwner({
    required String username,
    required String password,
    required String ownerName,
    required String mobile,
    String? companyName,
  }) async {
    if (await hasOwnerAccount()) {
      return const AuthResult(AuthResultCode.failure,
          'This installation already has an owner account.');
    }
    final identifier = username.trim();
    final validUsername =
        RegExp(r'^[A-Za-z0-9._-]{3,32}$').hasMatch(identifier);
    final validEmail =
        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(identifier);
    if ((!validUsername && !validEmail) ||
        PasswordPolicy.validate(password) != null ||
        ownerName.trim().isEmpty ||
        (companyName != null &&
            (!validEmail ||
                companyName.trim().isEmpty ||
                !RegExp(r'^\d{10}$').hasMatch(mobile.trim())))) {
      return const AuthResult(AuthResultCode.failure,
          'Enter an owner name, valid login email, 10-digit mobile number, company name, and a password with at least 8 characters including a letter and number.');
    }
    try {
      final passwordSalt = _hasher.newSalt();
      final recoverySalt = _hasher.newSalt();
      final recoveryCode = _hasher.newRecoveryCode();
      final now = DateTime.now().toUtc().toIso8601String();
      await _accounts.create({
        'uid': const Uuid().v4(),
        'username': validEmail ? identifier.toLowerCase() : identifier,
        'name': ownerName.trim(),
        'mobile': mobile.trim(),
        'registration_company_name': companyName?.trim(),
        'password_salt': passwordSalt,
        'password_hash': await _hasher.hash(password, passwordSalt),
        'recovery_salt': recoverySalt,
        'recovery_hash': await _hasher.hash(recoveryCode, recoverySalt),
        'created_at': now,
        'updated_at': now,
      });
      return AuthResult(AuthResultCode.success, 'Local owner account created.',
          recoveryCode: recoveryCode);
    } catch (_) {
      return const AuthResult(AuthResultCode.failure,
          'Local account could not be created. Please retry.');
    }
  }

  @override
  Future<void> signOut() async {
    await _sessions.clear();
    _signedInUid = null;
    _changes.add(null);
  }

  Future<Map<String, dynamic>?> getUserDetails() async {
    final record = await _accounts.read();
    if (record == null || record['uid'] != _signedInUid) return null;
    return {
      'uid': record['uid'],
      'username': record['username'],
      'name': record['name'],
      'mobile': record['mobile'],
      'registrationCompanyName': record['registration_company_name'],
      'role': 'OWNER',
      'isActive': true,
      'createdAt': record['created_at'],
      'lastPasswordChangedAt': record['last_password_changed_at'],
    };
  }

  Future<AuthResult> updateProfile(
      {required String name, required String mobile}) async {
    if (_signedInUid == null || name.trim().isEmpty) {
      return const AuthResult(
          AuthResultCode.failure, 'Sign in and enter a name.');
    }
    await _accounts.update({
      'name': name.trim(),
      'mobile': mobile.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    return const AuthResult(AuthResultCode.success, 'Profile updated.');
  }

  Future<AuthResult> changePassword(
      {required String currentPassword, required String newPassword}) async {
    final record = await _accounts.read();
    if (record == null || record['uid'] != _signedInUid) {
      return const AuthResult(AuthResultCode.failure, 'Sign in again.');
    }
    if (!await _hasher.verify(
        currentPassword,
        record['password_salt'] as List<int>,
        record['password_hash'] as List<int>)) {
      return const AuthResult(
          AuthResultCode.failure, 'Current password is incorrect.');
    }
    if (currentPassword == newPassword) {
      return const AuthResult(AuthResultCode.failure,
          'Choose a password different from the current password.');
    }
    final passwordError = PasswordPolicy.validate(newPassword);
    if (passwordError != null) {
      return AuthResult(AuthResultCode.failure, passwordError);
    }
    final salt = _hasher.newSalt();
    final passwordChangedAt = DateTime.now().toUtc().toIso8601String();
    await _accounts.update({
      'password_salt': salt,
      'password_hash': await _hasher.hash(newPassword, salt),
      'updated_at': passwordChangedAt,
      'last_password_changed_at': passwordChangedAt,
    });
    _otpChallenge = null;
    return const AuthResult(AuthResultCode.success, 'Password updated.');
  }

  @override
  Future<AuthResult> resetPassword(
      {required String recoveryCode, required String newPassword}) async {
    final passwordError = PasswordPolicy.validate(newPassword);
    if (passwordError != null) {
      return AuthResult(AuthResultCode.failure, passwordError);
    }
    final record = await _accounts.read();
    if (record == null ||
        !await _hasher.verify(
            recoveryCode.trim().toUpperCase(),
            record['recovery_salt'] as List<int>,
            record['recovery_hash'] as List<int>)) {
      return const AuthResult(
          AuthResultCode.failure, 'Recovery code is incorrect.');
    }
    return _replacePassword(newPassword);
  }

  Future<AuthResult> sendRecoveryEmailEnrollment({
    required String currentPassword,
    required String email,
  }) async {
    final record = await _accounts.read();
    if (record == null || record['uid'] != _signedInUid) {
      return const AuthResult(AuthResultCode.failure, 'Sign in again.');
    }
    final passwordCheck = await _checkCurrentPassword(record, currentPassword);
    if (passwordCheck != null) return passwordCheck;
    final normalized = _normalizeEmail(email);
    if (normalized == null) {
      return const AuthResult(
          AuthResultCode.failure, 'Enter a valid email address.');
    }
    if (_companyEmailMismatch(record, normalized)) {
      return const AuthResult(AuthResultCode.failure,
          'Use the company sign-in email for password recovery.');
    }
    return _sendEmail(normalized);
  }

  Future<AuthResult> linkRecoveryToGoogleAccount({
    required String currentPassword,
    required String email,
    required String googleSubject,
  }) async {
    final record = await _accounts.read();
    if (record == null || record['uid'] != _signedInUid) {
      return const AuthResult(AuthResultCode.failure, 'Sign in again.');
    }
    final passwordCheck = await _checkCurrentPassword(record, currentPassword);
    if (passwordCheck != null) return passwordCheck;
    final normalized = _normalizeEmail(email);
    if (normalized == null || googleSubject.trim().isEmpty) {
      return const AuthResult(AuthResultCode.failure,
          'Google did not return a verified account identity.');
    }
    if (_companyEmailMismatch(record, normalized)) {
      return const AuthResult(AuthResultCode.failure,
          'Choose the company sign-in email in Google sign-in.');
    }
    await _accounts.update({
      'recovery_email': normalized,
      'recovery_google_subject': googleSubject,
      'recovery_email_uid': record['recovery_email'] == normalized
          ? record['recovery_email_uid']
          : null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    return const AuthResult(AuthResultCode.success,
        'Google account is linked for password recovery.');
  }

  Future<AuthResult> linkNewCompanyToGoogle({
    required String email,
    required String password,
    required String googleSubject,
  }) async {
    final normalized = _normalizeEmail(email);
    final record = await _accounts.read();
    if (normalized == null ||
        record == null ||
        record['username'] != normalized ||
        (record['registration_company_name'] as String? ?? '').isEmpty ||
        record['recovery_google_subject'] != null ||
        googleSubject.trim().isEmpty) {
      return const AuthResult(AuthResultCode.failure,
          'The verified Google account does not match this company.');
    }
    final passwordCheck = await _checkCurrentPassword(record, password);
    if (passwordCheck != null) return passwordCheck;
    await _accounts.update({
      'recovery_email': normalized,
      'recovery_google_subject': googleSubject,
      'recovery_email_uid': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    return const AuthResult(AuthResultCode.success,
        'Google account linked for backup and password recovery.');
  }

  Future<void> unlinkGoogleRecovery() async {
    final record = await _accounts.read();
    if (record == null || record['uid'] != _signedInUid) {
      throw StateError('Sign in again to change the recovery account.');
    }
    await _accounts.update({
      'recovery_google_subject': null,
      'recovery_email': record['recovery_email_uid'] == null
          ? null
          : record['recovery_email'],
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    _otpChallenge = null;
  }

  Future<AuthResult> confirmRecoveryEmailEnrollment({
    required String currentPassword,
    required String email,
    required String link,
  }) async {
    final record = await _accounts.read();
    if (record == null || record['uid'] != _signedInUid) {
      return const AuthResult(AuthResultCode.failure, 'Sign in again.');
    }
    final passwordCheck = await _checkCurrentPassword(record, currentPassword);
    if (passwordCheck != null) return passwordCheck;
    final normalized = _normalizeEmail(email);
    if (normalized == null) {
      return const AuthResult(
          AuthResultCode.failure, 'Enter a valid email address.');
    }
    if (_companyEmailMismatch(record, normalized)) {
      return const AuthResult(AuthResultCode.failure,
          'Use the company sign-in email for password recovery.');
    }
    if (!isEmailRecoveryAvailable) {
      return const AuthResult(AuthResultCode.failure,
          'Email recovery is not configured on this installation.');
    }
    try {
      final verified = await _email!.verifySignInLink(normalized, link);
      if (verified.email != normalized) {
        return const AuthResult(AuthResultCode.failure,
            'The link belongs to a different email address.');
      }
      await _accounts.update({
        'recovery_email': normalized,
        'recovery_email_uid': verified.uid,
        'recovery_google_subject': record['recovery_email'] == normalized
            ? record['recovery_google_subject']
            : null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      return const AuthResult(
          AuthResultCode.success, 'Recovery email verified.');
    } on EmailRecoveryException catch (error) {
      return AuthResult(AuthResultCode.failure, error.message);
    }
  }

  Future<AuthResult> sendPasswordResetEmail(String email) async {
    final normalized = _normalizeEmail(email);
    if (normalized == null) {
      return const AuthResult(
          AuthResultCode.failure, 'Enter a valid email address.');
    }
    final record = await _accounts.read();
    if (record?['recovery_email'] != normalized ||
        (record?['recovery_email_uid'] == null &&
            record?['recovery_google_subject'] == null)) {
      return const AuthResult(AuthResultCode.success,
          'If this email is registered, a recovery link will arrive shortly.');
    }
    final sent = await _sendEmail(normalized);
    return sent.isSuccess
        ? const AuthResult(AuthResultCode.success,
            'If this email is registered, a recovery link will arrive shortly.')
        : sent;
  }

  Future<AuthResult> resetPasswordWithEmail({
    required String email,
    required String link,
    required String newPassword,
  }) async {
    if (!isEmailRecoveryAvailable) {
      return const AuthResult(AuthResultCode.failure,
          'Email recovery is not configured on this installation.');
    }
    final passwordError = PasswordPolicy.validate(newPassword);
    if (passwordError != null) {
      return AuthResult(AuthResultCode.failure, passwordError);
    }
    final normalized = _normalizeEmail(email);
    final record = await _accounts.read();
    if (normalized == null ||
        record?['recovery_email'] != normalized ||
        (record?['recovery_email_uid'] == null &&
            record?['recovery_google_subject'] == null)) {
      return const AuthResult(
          AuthResultCode.failure, 'This email is not registered for recovery.');
    }
    try {
      final verified = await _email!.verifySignInLink(normalized, link);
      if (verified.email != normalized ||
          (record!['recovery_email_uid'] != null &&
              verified.uid != record['recovery_email_uid'])) {
        return const AuthResult(AuthResultCode.failure,
            'This link does not match the registered recovery email.');
      }
      if (record['recovery_email_uid'] == null) {
        await _accounts.update({'recovery_email_uid': verified.uid});
      }
      return _replacePassword(newPassword);
    } on EmailRecoveryException catch (error) {
      return AuthResult(AuthResultCode.failure, error.message);
    }
  }

  @override
  Future<AuthResult> sendPasswordResetOtp(String email) async {
    final normalized = _normalizeEmail(email);
    if (normalized == null) {
      return const AuthResult(
          AuthResultCode.failure, 'Enter a valid email address.');
    }
    final now = _clock().toUtc();
    if (_otpSending) {
      return const AuthResult(
          AuthResultCode.failure, 'A verification code is already being sent.');
    }
    if (_lastOtpSentAt != null &&
        now.difference(_lastOtpSentAt!) < const Duration(minutes: 1)) {
      return const AuthResult(AuthResultCode.failure,
          'Wait one minute before requesting another code.');
    }
    _otpSending = true;
    try {
      _otpChallenge = null;
      final record = await _accounts.read();
      final subject = record?['recovery_google_subject'] as String?;
      if (record?['recovery_email'] != normalized ||
          subject == null ||
          subject.isEmpty) {
        return const AuthResult(AuthResultCode.failure,
            'Email OTP is not set up for this account. Connect your Google account in Backup & Restore, or use your saved recovery code.');
      }
      if (_otpEmail == null) {
        return const AuthResult(AuthResultCode.failure,
            'Email OTP delivery is unavailable on this installation.');
      }
      final random = Random.secure();
      final code = random.nextInt(1000000).toString().padLeft(6, '0');
      final nonce = List<int>.generate(32, (_) => random.nextInt(256));
      try {
        await _otpEmail.send(
            email: normalized, googleSubject: subject, code: code);
      } on OtpEmailException catch (error) {
        return AuthResult(AuthResultCode.failure, error.message);
      } catch (_) {
        return const AuthResult(AuthResultCode.failure,
            'Could not send the code. Check your connection and try again.');
      }
      _lastOtpSentAt = _clock().toUtc();
      _otpChallenge = _OtpChallenge(
        email: normalized,
        accountId: record!['uid'] as String,
        googleSubject: subject,
        nonce: nonce,
        digest: sha256.convert([...nonce, ...utf8.encode(code)]).bytes,
        expiresAt: _lastOtpSentAt!.add(const Duration(minutes: 10)),
      );
      return const AuthResult(AuthResultCode.success,
          'If this email is registered, a verification code will arrive shortly.');
    } finally {
      _otpSending = false;
    }
  }

  @override
  Future<AuthResult> verifyPasswordResetOtp({
    required String email,
    required String code,
  }) async {
    final challenge = _otpChallenge;
    final now = _clock().toUtc();
    if (challenge == null ||
        challenge.email != _normalizeEmail(email) ||
        !RegExp(r'^\d{6}$').hasMatch(code) ||
        !challenge.expiresAt.isAfter(now) ||
        challenge.attempts >= 5) {
      return const AuthResult(AuthResultCode.failure,
          'The code is invalid or expired. Request a new code.');
    }
    challenge.attempts++;
    final received =
        sha256.convert([...challenge.nonce, ...utf8.encode(code)]).bytes;
    var difference = 0;
    for (var i = 0; i < received.length; i++) {
      difference |= received[i] ^ challenge.digest[i];
    }
    if (difference != 0) {
      if (challenge.attempts >= 5) _otpChallenge = null;
      return const AuthResult(AuthResultCode.failure,
          'The code is invalid or expired. Request a new code.');
    }
    challenge.verified = true;
    return const AuthResult(AuthResultCode.success, 'Email verified.');
  }

  @override
  Future<AuthResult> resetPasswordWithOtp({
    required String email,
    required String newPassword,
  }) async {
    final error = PasswordPolicy.validate(newPassword);
    if (error != null) return AuthResult(AuthResultCode.failure, error);
    final challenge = _otpChallenge;
    final record = await _accounts.read();
    if (challenge == null ||
        !challenge.verified ||
        !challenge.expiresAt.isAfter(_clock().toUtc()) ||
        challenge.email != _normalizeEmail(email) ||
        challenge.accountId != record?['uid'] ||
        challenge.email != record?['recovery_email'] ||
        challenge.googleSubject != record?['recovery_google_subject']) {
      return const AuthResult(
          AuthResultCode.failure, 'Verification expired. Request a new code.');
    }
    return _replacePassword(newPassword);
  }

  Future<AuthResult> _replacePassword(String newPassword) async {
    final passwordSalt = _hasher.newSalt();
    final recoverySalt = _hasher.newSalt();
    final nextRecoveryCode = _hasher.newRecoveryCode();
    final changedAt = DateTime.now().toUtc().toIso8601String();
    await _accounts.update({
      'password_salt': passwordSalt,
      'password_hash': await _hasher.hash(newPassword, passwordSalt),
      'recovery_salt': recoverySalt,
      'recovery_hash': await _hasher.hash(nextRecoveryCode, recoverySalt),
      'failed_attempts': 0,
      'locked_until': null,
      'updated_at': changedAt,
      'last_password_changed_at': changedAt,
    });
    _otpChallenge = null;
    await signOut();
    return AuthResult(AuthResultCode.success, 'Password reset.',
        recoveryCode: nextRecoveryCode);
  }

  Future<AuthResult> _sendEmail(String email) async {
    if (!isEmailRecoveryAvailable) {
      return const AuthResult(AuthResultCode.failure,
          'Email recovery is not configured on this installation.');
    }
    final now = DateTime.now().toUtc();
    if (_lastEmailSentAt != null &&
        now.difference(_lastEmailSentAt!) < const Duration(minutes: 1)) {
      return const AuthResult(AuthResultCode.failure,
          'Wait one minute before requesting another link.');
    }
    try {
      await _email!.sendSignInLink(email);
      _lastEmailSentAt = now;
      return const AuthResult(AuthResultCode.success, 'Email link sent.');
    } on EmailRecoveryException catch (error) {
      return AuthResult(AuthResultCode.failure, error.message);
    }
  }

  Future<AuthResult?> _checkCurrentPassword(
      Map<String, Object?> record, String password) async {
    final now = DateTime.now().toUtc();
    final lockedUntil =
        DateTime.tryParse(record['locked_until'] as String? ?? '');
    if (lockedUntil != null && lockedUntil.isAfter(now)) {
      return const AuthResult(AuthResultCode.failure,
          'Too many attempts. Try again in a few minutes.');
    }
    if (!await _hasher.verify(password, record['password_salt'] as List<int>,
        record['password_hash'] as List<int>)) {
      await _recordFailedAttempt(record, now);
      return const AuthResult(
          AuthResultCode.failure, 'Current password is incorrect.');
    }
    await _accounts.update({'failed_attempts': 0, 'locked_until': null});
    return null;
  }

  static String? _normalizeEmail(String email) {
    final value = email.trim().toLowerCase();
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value) ? value : null;
  }

  static bool _companyEmailMismatch(
          Map<String, Object?> record, String email) =>
      (record['registration_company_name'] as String? ?? '').isNotEmpty &&
      record['username'] != email;
}

class _OtpChallenge {
  _OtpChallenge({
    required this.email,
    required this.accountId,
    required this.googleSubject,
    required this.nonce,
    required this.digest,
    required this.expiresAt,
  });

  final String email;
  final String accountId;
  final String googleSubject;
  final List<int> nonce;
  final List<int> digest;
  final DateTime expiresAt;
  int attempts = 0;
  bool verified = false;
}
