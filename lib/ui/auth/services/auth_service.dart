import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/logging/app_logger.dart';
import 'auth_result.dart';
import 'auth_session_gateway.dart';
import 'installation_account_binding.dart';

class AuthService implements AuthSessionGateway {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    InstallationAccountBinding? binding,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _binding = binding ?? InstallationAccountBinding();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final InstallationAccountBinding _binding;

  User? get currentUser => _auth.currentUser;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Stream<String?> authUserIds() =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  Future<SessionCheck> validateCurrentSession() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const SessionCheck(SessionCheckStatus.rejected, 'Sign in again.');
    }

    try {
      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed == null || refreshed.uid != user.uid) {
        return const SessionCheck(
          SessionCheckStatus.rejected,
          'Your session has ended. Sign in again.',
        );
      }

      final record = await _firestore.collection('users').doc(user.uid).get();
      if (!record.exists) {
        return const SessionCheck(
          SessionCheckStatus.rejected,
          'User record not found. Contact the administrator.',
        );
      }
      if (record.data()?['isActive'] != true) {
        return const SessionCheck(
          SessionCheckStatus.rejected,
          'This account is inactive. Contact the administrator.',
        );
      }
      if (!refreshed.emailVerified) {
        return const SessionCheck(
          SessionCheckStatus.verificationRequired,
          'Verify your email before signing in.',
        );
      }
      if (!await _binding.claimOrVerify(user.uid)) {
        return const SessionCheck(
          SessionCheckStatus.rejected,
          'This installation belongs to another owner account.',
        );
      }
      return const SessionCheck(SessionCheckStatus.authorized, '');
    } on FirebaseAuthException catch (error, stackTrace) {
      if (error.code == 'user-disabled' || error.code == 'user-not-found') {
        return const SessionCheck(
          SessionCheckStatus.rejected,
          'This account is unavailable. Contact the administrator.',
        );
      }
      AppLogger.warning('Session verification failed.',
          error: error, stackTrace: stackTrace);
      return const SessionCheck(
        SessionCheckStatus.unavailable,
        'Could not verify your session. Check your connection and retry.',
      );
    } catch (error, stackTrace) {
      AppLogger.warning('Session verification failed.',
          error: error, stackTrace: stackTrace);
      return const SessionCheck(
        SessionCheckStatus.unavailable,
        'Could not verify your session. Check your connection and retry.',
      );
    }
  }

  @override
  Future<AuthResult> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final check = await validateCurrentSession();
      if (!check.isAuthorized) {
        var verificationEmailSent = false;
        if (check.status == SessionCheckStatus.verificationRequired) {
          try {
            await _auth.currentUser?.sendEmailVerification();
            verificationEmailSent = true;
          } catch (error, stackTrace) {
            AppLogger.warning('Verification email resend failed.',
                error: error, stackTrace: stackTrace);
          }
        }
        await _auth.signOut();
        return AuthResult(
          check.status == SessionCheckStatus.verificationRequired
              ? AuthResultCode.verificationRequired
              : AuthResultCode.failure,
          check.status == SessionCheckStatus.verificationRequired
              ? verificationEmailSent
                  ? 'Verify your email to continue. A new link was sent.'
                  : 'Verify your email to continue. The link could not be sent; '
                      'try again later.'
              : check.message,
        );
      }

      try {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
          'lastLoginAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (error, stackTrace) {
        AppLogger.warning('Last sign-in timestamp could not be saved.',
            error: error, stackTrace: stackTrace);
      }
      return const AuthResult(
          AuthResultCode.success, 'Signed in successfully.');
    } on FirebaseAuthException catch (error) {
      await _signOutAfterFailure();
      return AuthResult(AuthResultCode.failure, _loginError(error.code));
    } catch (error, stackTrace) {
      AppLogger.error('Login failed unexpectedly.',
          error: error, stackTrace: stackTrace);
      await _signOutAfterFailure();
      return const AuthResult(
        AuthResultCode.failure,
        'Sign in could not be completed. Please try again.',
      );
    }
  }

  @override
  Future<AuthResult> registerOwner({
    required String email,
    required String password,
    required String ownerName,
    required String mobile,
  }) async {
    User? createdUser;
    try {
      if (!await _binding.canCreateOwner()) {
        return const AuthResult(
          AuthResultCode.failure,
          'This installation already has an owner account. Sign in instead.',
        );
      }
      final normalizedEmail = email.trim().toLowerCase();
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      createdUser = credential.user;
      if (createdUser == null) {
        return const AuthResult(
          AuthResultCode.failure,
          'Account could not be created. Please try again.',
        );
      }

      try {
        await _firestore.collection('users').doc(createdUser.uid).set({
          'uid': createdUser.uid,
          'name': ownerName.trim(),
          'email': normalizedEmail,
          'mobile': mobile.trim(),
          'role': 'OWNER',
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
      } catch (error, stackTrace) {
        AppLogger.error('Account record creation failed.',
            error: error, stackTrace: stackTrace);
        try {
          await createdUser.delete();
        } catch (rollbackError, rollbackStack) {
          AppLogger.error('Account rollback failed.',
              error: rollbackError, stackTrace: rollbackStack);
        }
        return const AuthResult(
          AuthResultCode.failure,
          'Account setup failed. Please try again or contact support.',
        );
      }

      try {
        await createdUser.sendEmailVerification();
        return const AuthResult(
          AuthResultCode.success,
          'Account created. Verify your email before signing in.',
        );
      } catch (error, stackTrace) {
        AppLogger.warning('Verification email could not be sent.',
            error: error, stackTrace: stackTrace);
        return const AuthResult(
          AuthResultCode.verificationDeliveryFailed,
          'Account created, but the verification email was not sent. '
          'Sign in to request a new link.',
        );
      }
    } on FirebaseAuthException catch (error) {
      return AuthResult(
        AuthResultCode.failure,
        switch (error.code) {
          'email-already-in-use' => 'Email is already registered.',
          'weak-password' => 'Choose a stronger password.',
          'invalid-email' => 'Enter a valid email address.',
          _ => 'Account could not be created. Please try again.',
        },
      );
    } catch (error, stackTrace) {
      AppLogger.error('Registration failed unexpectedly.',
          error: error, stackTrace: stackTrace);
      return const AuthResult(
        AuthResultCode.failure,
        'Account could not be created. Please try again.',
      );
    } finally {
      await _signOutAfterFailure();
    }
  }

  String _loginError(String code) => switch (code) {
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Email or password is incorrect.',
        'user-disabled' =>
          'This account is inactive. Contact the administrator.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        'network-request-failed' => 'Check your connection and try again.',
        _ => 'Sign in failed. Please try again.',
      };

  Future<void> _signOutAfterFailure() async {
    try {
      await _auth.signOut();
    } catch (error, stackTrace) {
      AppLogger.warning('Sign-out cleanup failed.',
          error: error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      return const AuthResult(
        AuthResultCode.success,
        'If this email has an account, a reset link has been sent.',
      );
    } catch (error, stackTrace) {
      AppLogger.warning('Password reset request failed.',
          error: error, stackTrace: stackTrace);
      return const AuthResult(
        AuthResultCode.failure,
        'Could not request a reset link. Check your connection and retry.',
      );
    }
  }

  Future<Map<String, dynamic>?> getUserDetails() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final record = await _firestore.collection('users').doc(user.uid).get();
      if (record.exists) return record.data();
    } catch (error, stackTrace) {
      AppLogger.warning('User profile fetch failed.',
          error: error, stackTrace: stackTrace);
    }
    return {
      'name': user.displayName ?? user.email?.split('@').first ?? 'User',
      'email': user.email ?? '',
      'mobile': user.phoneNumber ?? '',
      'role': 'STAFF',
      'uid': user.uid,
    };
  }
}
