import 'dart:async';

import 'package:uuid/uuid.dart';

import 'auth_result.dart';
import 'auth_session_gateway.dart';
import 'local_account_repository.dart';
import 'local_password_hasher.dart';
import 'local_session_store.dart';

class AuthService implements AuthSessionGateway {
  AuthService._(this._accounts, this._hasher, this._sessions);

  static final AuthService _instance = AuthService._(LocalAccountRepository(),
      LocalPasswordHasher(), const SecureLocalSessionStore());
  factory AuthService() => _instance;

  AuthService.forTesting(LocalAccountRepository accounts,
      {required LocalSessionStore sessionStore})
      : this._(accounts, LocalPasswordHasher(), sessionStore);

  final LocalAccountRepository _accounts;
  final LocalPasswordHasher _hasher;
  final LocalSessionStore _sessions;
  final _changes = StreamController<String?>.broadcast();
  String? _signedInUid;

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
        password.length < 8 ||
        ownerName.trim().isEmpty) {
      return const AuthResult(AuthResultCode.failure,
          'Enter an owner name, a valid username and a password of at least 8 characters.');
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
    if (newPassword.length < 8) {
      return const AuthResult(
          AuthResultCode.failure, 'Use at least 8 characters.');
    }
    final salt = _hasher.newSalt();
    await _accounts.update({
      'password_salt': salt,
      'password_hash': await _hasher.hash(newPassword, salt),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    return const AuthResult(AuthResultCode.success, 'Password updated.');
  }

  Future<AuthResult> resetPassword(
      {required String recoveryCode, required String newPassword}) async {
    if (newPassword.length < 8) {
      return const AuthResult(
          AuthResultCode.failure, 'Use at least 8 characters.');
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
    final passwordSalt = _hasher.newSalt();
    final recoverySalt = _hasher.newSalt();
    final nextRecoveryCode = _hasher.newRecoveryCode();
    await _accounts.update({
      'password_salt': passwordSalt,
      'password_hash': await _hasher.hash(newPassword, passwordSalt),
      'recovery_salt': recoverySalt,
      'recovery_hash': await _hasher.hash(nextRecoveryCode, recoverySalt),
      'failed_attempts': 0,
      'locked_until': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
    await signOut();
    return AuthResult(AuthResultCode.success, 'Password reset.',
        recoveryCode: nextRecoveryCode);
  }
}
