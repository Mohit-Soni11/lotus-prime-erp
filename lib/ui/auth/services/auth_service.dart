import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/logging/app_logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return "Unable to sign in right now. Please try again.";
      }

      await user.reload();
      final activeUser = _auth.currentUser;
      if (activeUser == null) {
        return "Session expired during sign in. Please try again.";
      }

      final userDoc =
          await _firestore.collection('users').doc(activeUser.uid).get();
      if (!userDoc.exists) {
        await _auth.signOut();
        return "User record not found. Contact Admin.";
      }

      final userData = userDoc.data() ?? const <String, dynamic>{};
      final isActive = userData['isActive'] as bool? ?? true;
      if (!isActive) {
        await _auth.signOut();
        return "This account is inactive. Contact Admin.";
      }

      if (!activeUser.emailVerified) {
        await _auth.signOut();
        return "Please verify your email before signing in.";
      }

      await _firestore.collection('users').doc(activeUser.uid).set({
        'email': normalizedEmail,
        'isEmailVerified': true,
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return "SUCCESS";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return "No user found with this email.";
      if (e.code == 'wrong-password') return "Incorrect Password.";
      if (e.code == 'invalid-credential') return "Invalid Credentials.";
      if (e.code == 'too-many-requests') return "Too many attempts. Try later.";
      return e.message ?? "Login Failed";
    } catch (e, stackTrace) {
      AppLogger.error(
        'Login failed unexpectedly.',
        error: e,
        stackTrace: stackTrace,
      );
      return "System Error: $e";
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String> registerOwner({
    required String email,
    required String password,
    required String ownerName,
    required String mobile,
    required String companyName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedOwnerName = ownerName.trim();
    final normalizedCompanyName = companyName.trim();
    final normalizedMobile = mobile.trim();

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        return "User creation failed";
      }

      final companyId = "CMP_${DateTime.now().millisecondsSinceEpoch}";
      final headOfficeId = "UNIT_${DateTime.now().millisecondsSinceEpoch}_HO";

      try {
        await _firestore.runTransaction((transaction) async {
          transaction.set(_firestore.collection('companies').doc(companyId), {
            'companyId': companyId,
            'name': normalizedCompanyName,
            'ownerId': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'plan': 'Enterprise',
            'isActive': true,
          });

          transaction.set(_firestore.collection('units').doc(headOfficeId), {
            'unitId': headOfficeId,
            'companyId': companyId,
            'name': '$normalizedCompanyName (Head Office)',
            'type': 'HEAD_OFFICE',
            'city': 'Main Location',
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          });

          transaction.set(_firestore.collection('users').doc(user.uid), {
            'uid': user.uid,
            'name': normalizedOwnerName,
            'email': normalizedEmail,
            'mobile': normalizedMobile,
            'role': 'OWNER',
            'companyId': companyId,
            'assignedUnits': ['ALL'],
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true,
            'isEmailVerified': false,
          });
        });
      } catch (e, stackTrace) {
        AppLogger.error(
          'Registration transaction failed. Rolling back auth user.',
          error: e,
          stackTrace: stackTrace,
        );
        await user.delete();
        return "Account setup failed. Please try again.";
      }

      try {
        await user.sendEmailVerification();
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Verification email could not be sent after registration.',
          error: e,
          stackTrace: stackTrace,
        );
      }

      return "SUCCESS";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return "Email is already registered.";
      }
      if (e.code == 'weak-password') return "Password is too weak.";
      return e.message ?? "Registration Error";
    } catch (e, stackTrace) {
      AppLogger.error(
        'Registration failed unexpectedly.',
        error: e,
        stackTrace: stackTrace,
      );
      return "Database Error: $e";
    }
  }

  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }

  Future<String> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return "SUCCESS";
      }
      return "ALREADY_VERIFIED";
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Verification email resend failed.',
        error: e,
        stackTrace: stackTrace,
      );
      return "Error: $e";
    }
  }

  Future<String> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      return "SUCCESS";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return "No user found with this email.";
      return e.message ?? "Error sending reset link.";
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Password reset request failed.',
        error: e,
        stackTrace: stackTrace,
      );
      return e.toString();
    }
  }

  Future<Map<String, dynamic>?> getUserDetails() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return doc.data();
        }
      }
    } catch (e, stackTrace) {
      AppLogger.warning(
        'User profile fetch failed. Falling back to Firebase Auth cache.',
        error: e,
        stackTrace: stackTrace,
      );
    }

    final user = _auth.currentUser;
    if (user != null) {
      return {
        'name': user.displayName ?? user.email?.split('@').first ?? 'User',
        'email': user.email ?? '',
        'mobile': user.phoneNumber ?? '',
        'role': 'OWNER',
        'uid': user.uid,
      };
    }
    return null;
  }
}
