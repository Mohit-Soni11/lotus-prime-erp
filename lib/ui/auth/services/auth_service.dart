import 'dart:async';

import 'package:uuid/uuid.dart';

import 'auth_result.dart';
import 'auth_session_gateway.dart';
import 'email_recovery_gateway.dart';
import 'firebase_email_recovery_gateway.dart';
import 'local_account_repository.dart';
import 'local_password_hasher.dart';
import 'password_policy.dart';
import 'local_session_store.dart';

class AuthService implements AuthSessionGateway {
  AuthService._(this._accounts, this._hasher, this._sessions, this._email);

  static final AuthService _instance = AuthService._(
      LocalAccountRepository(),
      LocalPasswordHasher(),
      const SecureLocalSessionStore(),
      FirebaseEmailRecoveryGateway(
        apiKey: const String.fromEnvironment('LOTUS_RECOVERY_API_KEY'),
        continueUrl: Uri.parse(
            const String.fromEnvironment('LOTUS_RECOVERY_CONTINUE_URL')),
      ));
  factory AuthService() => _instance;

  AuthService.forTesting(LocalAccountRepository accounts,
      {required LocalSessionStore sessionStore,
      EmailRecoveryGateway? emailGateway})
      : this._(accounts, LocalPasswordHasher(), sessionStore, emailGateway);

  final LocalAccountRepository _accounts;
  final LocalPasswordHasher _hasher;
  final LocalSessionStore _sessions;
  final EmailRecoveryGateway? _email;
  final _changes = StreamController<String?>.broadcast();
  String? _signedInUid;
  DateTime? _lastEmailSentAt;

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
  }) async {
    if (await hasOwnerAccount()) {
      return const AuthResult(AuthResultCode.failure,
          'This installation already has an owner account.');
    }
    if (!RegExp(r'^[A-Za-z0-9._-]{3,32}$').hasMatch(username.trim()) ||
        PasswordPolicy.validate(password) != null ||
        ownerName.trim().isEmpty) {
      return const AuthResult(AuthResultCode.failure,
          'Enter an owner name, a valid username, and a password with at least 8 characters including a letter and number.');
    }
    try {
      final passwordSalt = _hasher.newSalt();
      final recoverySalt = _hasher.newSalt();
      final recoveryCode = _hasher.newRecoveryCode();
      final now = DateTime.now().toUtc().toIso8601String();
      await _accounts.create({
        'uid': const Uuid().v4(),
        'username': username.trim(),
        'name': ownerName.trim(),
        'mobile': mobile.trim(),
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
    return const AuthResult(AuthResultCode.success, 'Password updated.');
  }

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
}
